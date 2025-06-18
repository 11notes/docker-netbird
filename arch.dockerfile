# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
  # GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      BUILD_ROOT="/go/netbird/management /go/netbird/relay /go/netbird/signal"

  # :: FOREIGN IMAGES
  FROM 11notes/nginx:stable AS distroless-nginx
  FROM 11notes/distroless:curl AS distroless-curl
  FROM 11notes/util AS util

# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
  # :: netbird
  FROM golang:1.24-alpine AS build
  COPY --from=util /usr/local/bin /usr/local/bin
  ARG APP_VERSION \
      BUILD_ROOT \
      BUILD_BIN

  ENV CGO_ENABLED=0

  RUN set -ex; \
    apk --update --no-cache add \
      build-base \
      upx \
      git;

  RUN set -ex; \
    git clone https://github.com/netbirdio/netbird -b v${APP_VERSION};

  RUN set -ex; \
    mkdir -p /distroless/usr/local/bin; \
    for BUILD in ${BUILD_ROOT}; do \
      cd ${BUILD}; \
      BIN="${BUILD}/$(echo ${BUILD} | awk -F '/' '{print $4}')"; \
      go build -ldflags="-extldflags=-static" -o ${BIN} main.go; \
      eleven checkStatic ${BIN}; \
      eleven strip ${BIN}; \
      cp ${BIN} /distroless/usr/local/bin; \
    done; \
    mv /distroless/usr/local/bin/management /distroless/usr/local/bin/netbird;

  # :: management
  FROM golang:1.24-alpine AS management
  COPY --from=util /usr/local/bin /usr/local/bin
  COPY ./build/go/management /go/management
  ENV CGO_ENABLED=0
  ARG BIN=/go/management/management

  RUN set -ex; \
    apk --update --no-cache add \
      build-base \
      upx; 

  RUN set -ex; \
    cd /go/management; \
    go build -ldflags="-extldflags=-static" -o ${BIN} main.go; \
    mkdir -p /distroless/usr/local/bin; \
    eleven checkStatic ${BIN}; \
    eleven strip ${BIN}; \
    cp ${BIN} /distroless/usr/local/bin;

  # :: dashboard
  FROM golang:1.24-alpine AS dashboard
  COPY --from=util /usr/local/bin /usr/local/bin
  COPY ./build/go/dashboard /go/dashboard
  ENV CGO_ENABLED=0
  ARG BIN=/go/dashboard/dashboard

  RUN set -ex; \
    apk --update --no-cache add \
      build-base \
      upx \
      git \
      nodejs \
      npm; 

  RUN set -ex; \
    cd /go/dashboard; \
    go build -ldflags="-extldflags=-static" -o ${BIN} main.go; \
    mkdir -p /distroless/usr/local/bin; \
    eleven checkStatic ${BIN}; \
    eleven strip ${BIN}; \
    cp ${BIN} /distroless/usr/local/bin;

  RUN set -ex; \
    git clone https://github.com/netbirdio/dashboard /dashboard;

  RUN set -ex; \
    cd /dashboard; \
    npm i --save; \
    echo '{}' > .local-config.json; \
    npm run build; \
    mkdir -p /distroless/nginx/var; \
    cp -R ./out/*  /distroless/nginx/var;

  # :: file system
  FROM alpine AS file-system
  COPY --from=util /usr/local/bin /usr/local/bin
  ARG APP_ROOT
  USER root

  RUN set -ex; \
    eleven mkdir /distroless${APP_ROOT}/{etc,var}; \
    mkdir -p /distroless/var/lib; \
    ln -sf ${APP_ROOT}/var /distroless/var/lib/netbird;
  

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

  # :: multi-stage
    COPY --from=build /distroless/ /
    COPY --from=dashboard --chown=${APP_UID}:${APP_GID} /distroless/ /
    COPY --from=management --chown=${APP_UID}:${APP_GID} /distroless/ /
    COPY --from=distroless-nginx --chown=${APP_UID}:${APP_GID} / /
    COPY --from=file-system --chown=${APP_UID}:${APP_GID} /distroless/ /
    COPY --from=distroless-curl /usr/local/bin /usr/local/bin
    COPY --chown=${APP_UID}:${APP_GID} ./rootfs/ /

# :: PERSISTENT DATA
  VOLUME ["${APP_ROOT}/etc", "${APP_ROOT}/var"]

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}