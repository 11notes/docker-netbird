![banner](https://raw.githubusercontent.com/11notes/static/refs/heads/master/img/banner/README.png)

# NETBIRD
![size](https://img.shields.io/badge/image_size-69MB-green?color=%2338ad2d)![5px](https://raw.githubusercontent.com/11notes/static/refs/heads/master/img/markdown/transparent5x2px.png)![pulls](https://img.shields.io/docker/pulls/11notes/netbird?color=2b75d6)![5px](https://raw.githubusercontent.com/11notes/static/refs/heads/master/img/markdown/transparent5x2px.png)[<img src="https://img.shields.io/github/issues/11notes/docker-netbird?color=7842f5">](https://github.com/11notes/docker-netbird/issues)![5px](https://raw.githubusercontent.com/11notes/static/refs/heads/master/img/markdown/transparent5x2px.png)![swiss_made](https://img.shields.io/badge/Swiss_Made-FFFFFF?labelColor=FF0000&logo=data:image/svg%2bxml;base64,PHN2ZyB2ZXJzaW9uPSIxIiB3aWR0aD0iNTEyIiBoZWlnaHQ9IjUxMiIgdmlld0JveD0iMCAwIDMyIDMyIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgogIDxyZWN0IHdpZHRoPSIzMiIgaGVpZ2h0PSIzMiIgZmlsbD0idHJhbnNwYXJlbnQiLz4KICA8cGF0aCBkPSJtMTMgNmg2djdoN3Y2aC03djdoLTZ2LTdoLTd2LTZoN3oiIGZpbGw9IiNmZmYiLz4KPC9zdmc+)

run netbird rootless and distroless.

# INTRODUCTION 📢

[NetBird](https://github.com/netbirdio/netbird) (created by [netbird](https://github.com/netbirdio)) combines a WireGuard-based overlay network with Zero Trust Network Access, providing a unified open source platform for reliable and secure connectivity. Create your own selfhosted ZTNA mesh network.

# CAUTION ⚠️
> [!CAUTION]
>Post tag 0.70.5 this image will now run the embedded IdP by default as well as using the unified management binary. If you were using an external IdP you can check the [guide](https://docs.netbird.io/selfhosted/migration/external-to-embedded-idp) from netbird what you can and need to do. This image is now also using the yml config and not the management.json anymore, please prepare your config accordingly!

# SYNOPSIS 📖
**What can I do with this?** This image will run netbird from a single image (not multiple) [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) and [distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md) for more security and convenience. Since this image supports all netbird images as a single image, the dashboard image needs a custom command entry (see the compose [example](https://github.com/11notes/docker-netbird/blob/master/compose.yml#L41)). The init binary will also replace all environment variables present in the default.yml config file, in either the format ${VAR} or $VAR. The default config can be customized with environment variables, your own file or an [inline config](https://github.com/11notes/RTFM/blob/master/linux/container/image/11notes/inline-config.md), whatever you prefer. The default config is using the embedded IdP, you can then add your Keycloak or any other external IdP as well.


# UNIQUE VALUE PROPOSITION 💶
**Why should I run this image and not the other image(s) that already exist?** Good question! Because ...

> [!IMPORTANT]
>* ... this image runs [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) as 1000:1000
>* ... this image has no shell since it is [distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md)
>* ... this image is auto updated to the latest version via CI/CD
>* ... this image has a health check
>* ... this image runs read-only
>* ... this image is automatically scanned for CVEs before and after publishing
>* ... this image is created via a secure and pinned CI/CD process
>* ... this image is very small
>* ... this image creates random entries for unset keys and hashes from the default config
>* ... this image supports [inline configs](https://github.com/11notes/RTFM/blob/master/linux/container/image/11notes/inline-config.md)

If you value security, simplicity and optimizations to the extreme, then this image might be for you.

# COMPARISON 🏁
Below you find a comparison between this image and the most used or original one.

| **image** | **size on disk** | **init default as** | **[distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md)** | supported architectures
| ---: | ---: | :---: | :---: | :---: |
| 11notes/netbird | 69MB | 1000:1000 | ✅ | amd64, arm64 |
| netbirdio/* | 330MB | 0:0 | ❌ | amd64, arm64, armv7 |

# VOLUMES 📁
* **/netbird/etc** - Directory of your config
* **/netbird/var** - Directory of dynamic data created by netbird

# DEFAULT CONFIG 📑
```yaml
server:
  listenAddress: ":8080"
  metricsPort: 9090
  healthcheckAddress: ":9000"

  logLevel: "info"
  logFile: "console"

  exposedAddress: "https://${NETBIRD_FQDN}:443"
  authSecret: "APP_SERVER_DEFAULT_AUTH_SECRET"
  dataDir: "/netbird/var/"
  disableAnonymousMetrics: true
  disableGeoliteUpdate: false

  auth:
    issuer: "https://${NETBIRD_FQDN}/oauth2"
    localAuthDisabled: false
    signKeyRefreshEnabled: true
    sessionCookieEncryptionKey: "APP_SERVER_DEFAULT_SESSION_COOKIE_ENCRYPTION_KEY"
    dashboardRedirectURIs:
      - "https://${NETBIRD_FQDN}/#callback"
      - "https://${NETBIRD_FQDN}/#silent-callback"
    dashboardPostLogoutRedirectURIs:
      - "https://${NETBIRD_FQDN}/"
    cliRedirectURIs:
      - "http://localhost:53000/"

  store:
    engine: "postgres"
    dsn: "host=postgres user=postgres password=${POSTGRES_PASSWORD} dbname=postgres port=5432 sslmode=disable"
    encryptionKey: "APP_SERVER_DEFAULT_ENCRYPTION_KEY"

  activityStore:
    engine: "postgres"
    dsn: "host=postgres user=postgres password=${POSTGRES_PASSWORD} dbname=postgres port=5432 sslmode=disable"

  authStore:
    engine: "postgres"
    dsn: "host=postgres user=postgres password=${POSTGRES_PASSWORD} dbname=postgres port=5432 sslmode=disable"
```

# COMPOSE ✂️
```yaml
name: "netbird"

x-lockdown: &lockdown
  # prevents write access to the image itself
  read_only: true
  # prevents any process within the container to gain more privileges
  security_opt:
    - "no-new-privileges=true"

x-image-netbird: &image
  image: "11notes/netbird:0.74.7"
  <<: *lockdown

services:
  server:
    depends_on:
      postgres:
        condition: "service_healthy"
        restart: true
    <<: *image
    environment:
      TZ: "Europe/Zurich"
      NETBIRD_FQDN: "${NETBIRD_FQDN}"
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
    volumes:
      - "server.etc:/netbird/etc"
      - "server.var:/netbird/var"
    tmpfs:
      - "/tmp:uid=1000,gid=1000"
    networks:
      frontend:
      backend:
    ports:
      - "3478:3478/udp"
      - "8080:8080/tcp"
    restart: "always"

  dashboard:
    <<: *image
    # start dashboard instead of mangement server
    command: "--dashboard"
    environment:
      TZ: "Europe/Zurich"
      NETBIRD_MGMT_API_ENDPOINT: "https://${NETBIRD_FQDN}"
      NETBIRD_MGMT_GRPC_API_ENDPOINT: "https://${NETBIRD_FQDN}"
      AUTH_AUTHORITY: "https://${NETBIRD_FQDN}/oauth2"
    volumes:
      - "dashboard.var:/nginx/var"
    tmpfs:
      - "/nginx/cache:uid=1000,gid=1000"
      - "/nginx/run:uid=1000,gid=1000"
    networks:
      frontend:
      backend:
    ports:
      - "3000:3000/tcp"
    restart: "always"

  postgres:
    # for more information about this image checkout:
    # https://github.com/11notes/docker-postgres
    image: "11notes/postgres:18"
    <<: *lockdown
    environment:
      TZ: "Europe/Zurich"
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
      POSTGRES_BACKUP_SCHEDULE: "0 3 * * *"
    volumes:
      - "postgres.etc:/postgres/etc"
      - "postgres.var:/postgres/var"
      - "postgres.backup:/postgres/backup"
    tmpfs:
      - "/postgres/run:uid=1000,gid=1000"
      - "/postgres/log:uid=1000,gid=1000"
    networks:
      backend:
    restart: "always"

volumes:
  server.etc:
  server.var:
  dashboard.var:
  postgres.etc:
  postgres.var:
  postgres.backup:

networks:
  frontend:
  backend:
    internal: true
```
To find out how you can change the default UID/GID of this container image, consult the [RTFM](https://github.com/11notes/RTFM/blob/main/linux/container/image/11notes/how-to.changeUIDGID.md#change-uidgid-the-correct-way).

# DEFAULT SETTINGS 🗃️
| Parameter | Value | Description |
| --- | --- | --- |
| `user` | docker | user name |
| `uid` | 1000 | [user identifier](https://en.wikipedia.org/wiki/User_identifier) |
| `gid` | 1000 | [group identifier](https://en.wikipedia.org/wiki/Group_identifier) |
| `home` | /netbird | home directory of user docker |

# ENVIRONMENT 📝
| Parameter | Value | Default |
| --- | --- | --- |
| `TZ` | [Time Zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) | |
| `DEBUG` | Will activate debug option for container image and app (if available) | |

# MAIN TAGS 🏷️
These are the main tags for the image. There is also a tag for each commit and its shorthand sha256 value.

* [0.74.7](https://hub.docker.com/r/11notes/netbird/tags?name=0.74.7)
* [0.74.7-unraid](https://hub.docker.com/r/11notes/netbird/tags?name=0.74.7-unraid)
* [0.74.7-nobody](https://hub.docker.com/r/11notes/netbird/tags?name=0.74.7-nobody)

### There is no latest tag, what am I supposed to do about updates?
It is my opinion that the ```:latest``` tag is a bad habbit and should not be used at all. Many developers introduce **breaking changes** in new releases. This would messed up everything for people who use ```:latest```. If you don’t want to change the tag to the latest [semver](https://semver.org/), simply use the short versions of [semver](https://semver.org/). Instead of using ```:0.74.7``` you can use ```:0``` or ```:0.74```. Since on each new version these tags are updated to the latest version of the software, using them is identical to using ```:latest``` but at least fixed to a major or minor version. Which in theory should not introduce breaking changes.

If you still insist on having the bleeding edge release of this app, simply use the ```:rolling``` tag, but be warned! You will get the latest version of the app instantly, regardless of breaking changes or security issues or what so ever. You do this at your own risk!

# REGISTRIES ☁️
```
docker pull 11notes/netbird:0.74.7
docker pull ghcr.io/11notes/netbird:0.74.7
docker pull quay.io/11notes/netbird:0.74.7
```

# UNRAID VERSION 🟠
This image supports unraid by default. Simply add **-unraid** to any tag and the image will run as 99:100 instead of 1000:1000.

# NOBODY VERSION 👻
This image supports nobody by default. Simply add **-nobody** to any tag and the image will run as 65534:65534 instead of 1000:1000.

# SOURCE 💾
* [11notes/netbird](https://github.com/11notes/docker-netbird)

# PARENT IMAGE 🏛️
> [!IMPORTANT]
>This image is not based on another image but uses [scratch](https://hub.docker.com/_/scratch) as the starting layer.
>The image consists of the following distroless layers that were added:
>* [11notes/distroless:localhealth](https://github.com/11notes/docker-distroless/blob/master/localhealth.dockerfile) - app to execute HTTP requests only on 127.0.0.1
>* 11notes/distroless:nginx

# BUILT WITH 🧰
* [netbirdio/netbird](https://github.com/netbirdio/netbird)

# GENERAL TIPS 📌
> [!TIP]
>* Use a reverse proxy like Traefik, Nginx, HAproxy to terminate TLS and to protect your endpoints
>* Use Let’s Encrypt DNS-01 challenge to obtain valid SSL certificates for your services

# CAUTION ⚠️
> [!CAUTION]
>* Because this image is distroless, it only works with PostgreSQL/MySQL, **not SQLite**!

# ElevenNotes™️
This image is provided to you at your own risk. Always make backups before updating an image to a different version. Check the [releases](https://github.com/11notes/docker-netbird/releases) for breaking changes. If you have any problems with using this image simply raise an [issue](https://github.com/11notes/docker-netbird/issues), thanks. If you have a question or inputs please create a new [discussion](https://github.com/11notes/docker-netbird/discussions) instead of an issue. You can find all my other repositories on [github](https://github.com/11notes?tab=repositories).

*created 18.07.2026, 06:05:35 (CET)*