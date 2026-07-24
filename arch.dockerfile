# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      APP_GO_VERSION=0

# :: FOREIGN IMAGES
  FROM 11notes/nginx:stable AS distroless-nginx
  FROM 11notes/distroless:localhealth AS distroless-localhealth
  FROM 11notes/distroless AS distroless
  FROM 11notes/util AS util
  FROM 11notes/distroless:curl AS distroless-curl

# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: ENTRYPOINT
  FROM 11notes/go:${APP_GO_VERSION} AS entrypoint
  COPY ./build/go/entrypoint /go/entrypoint
  RUN set -ex; \
    cd /go/entrypoint; \
    eleven go build /entrypoint main.go; \
    eleven distroless /entrypoint;

# :: NETBIRD
  FROM 11notes/go:${APP_GO_VERSION} AS build
  ARG APP_VERSION \
      BUILD_SRC=netbirdio/netbird.git \
      BUILD_ROOT=/go/netbird \
      BUILD_BIN=/netbird

  RUN set -eux; \
    eleven git clone ${BUILD_SRC} v${APP_VERSION};

  RUN set -eux; \
    # :: patch Netbird to not require cgo and produce a static binary
    cd ${BUILD_ROOT}; \
    sed -i 's|"gorm.io/driver/sqlite"|"github.com/glebarez/sqlite"|' ${BUILD_ROOT}/management/server/geolocation/database.go; \
    sed -i 's|"gorm.io/driver/sqlite"|"github.com/glebarez/sqlite"|' ${BUILD_ROOT}/management/server/geolocation/store.go; \
    go mod tidy; \
    DEX_PATH=$(go list -m -f '{{.Dir}}' github.com/dexidp/dex); \
    cp -af ${DEX_PATH}/. /go/dex; \
    go mod edit -replace github.com/dexidp/dex=/go/dex;

  COPY ./build/go/dex /go/dex

  RUN set -eux; \
    cd ${BUILD_ROOT}; \
    eleven go patch github.com/jackc/pgx/v5 v5.9.0 CVE-2026-33816;

  RUN set -eux; \
    cd ${BUILD_ROOT}; \
    sed -i 's/"development"/"v'${APP_VERSION}'"/' ${BUILD_ROOT}/version/version.go; \
    eleven go build ${BUILD_BIN} ./combined; \
    eleven distroless ${BUILD_BIN};

# :: DASHBOARD
  FROM alpine AS dashboard
  ARG APP_DASHBOARD_VERSION
  ENV NEXT_PUBLIC_DASHBOARD_VERSION="v${APP_DASHBOARD_VERSION}"

  RUN set -eux; \
    apk --update --no-cache add \
      curl \
      jq \
      git \
      nodejs \
      npm;

  RUN set -ex; \
    eleven git clone https://github.com/netbirdio/dashboard v${APP_DASHBOARD_VERSION};

  RUN set -ex; \
    cd /dashboard; \
    npm install; \
    echo '{}' > .local-config.json; \
    npm run build; \
    mkdir -p /distroless/nginx/var; \
    cp -R ./out/*  /distroless/nginx/var;

# :: FILE SYSTEM
  FROM alpine AS file-system
  COPY --from=util / /
  ARG APP_ROOT
  USER root

  RUN set -eux; \
    eleven mkdir /distroless${APP_ROOT}/{etc,var};


# ╔═════════════════════════════════════════════════════╗
# ║                       IMAGE                         ║
# ╚═════════════════════════════════════════════════════╝
  # :: HEADER
  FROM scratch

  # :: default arguments
    ARG TARGETPLATFORM \
        TARGETOS \
        TARGETARCH \
        TARGETVARIANT \
        APP_IMAGE \
        APP_NAME \
        APP_VERSION \
        APP_ROOT \
        APP_UID \
        APP_GID \
        APP_NO_CACHE

  # :: default environment
    ENV APP_IMAGE=${APP_IMAGE} \
        APP_NAME=${APP_NAME} \
        APP_VERSION=${APP_VERSION} \
        APP_ROOT=${APP_ROOT}

  # :: app specific environment
    ENV AUTH_AUDIENCE="netbird-dashboard" \
        AUTH_CLIENT_ID="netbird-dashboard" \
        AUTH_CLIENT_SECRET="" \
        USE_AUTH0="false" \
        AUTH_SUPPORTED_SCOPES="openid profile email groups" \
        AUTH_REDIRECT_URI="/#callback" \
        AUTH_SILENT_REDIRECT_URI="/#silent-callback" \
        NETBIRD_TOKEN_SOURCE="accessToken" \
        NETBIRD_DRAG_QUERY_PARAMS="false" \
        NGINX_SSL_PORT=443 \
        LETSENCRYPT_DOMAIN="none" \
        NETBIRD_HOTJAR_TRACK_ID="" \
        NETBIRD_GOOGLE_ANALYTICS_ID="" \
        NETBIRD_GOOGLE_TAG_MANAGER_ID="" \
        NETBIRD_WASM_PATH=""

  # :: multi-stage
    COPY --from=distroless / /
    COPY --from=distroless-localhealth / /
    COPY --from=entrypoint /distroless/ /
    COPY --from=build /distroless/ /
    COPY --from=dashboard --chown=${APP_UID}:${APP_GID} /distroless/ /
    COPY --from=distroless-nginx --chown=${APP_UID}:${APP_GID} / /
    COPY --from=file-system --chown=${APP_UID}:${APP_GID} /distroless/ /
    COPY --chown=${APP_UID}:${APP_GID} ./rootfs/ /

    COPY --from=distroless-curl / /

# :: PERSISTENT DATA
  VOLUME ["${APP_ROOT}/etc", "${APP_ROOT}/var"]

# :: MONITORING
  HEALTHCHECK --interval=5s --timeout=2s --start-period=5s \
    CMD ["/usr/local/bin/localhealth", "http://127.0.0.1:9000/health"]

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/entrypoint"]