![banner](https://github.com/11notes/defaults/blob/main/static/img/banner.png?raw=true)

# NETBIRD
![size](https://img.shields.io/docker/image-size/11notes/netbird/0.54.1?color=0eb305)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)![version](https://img.shields.io/docker/v/11notes/netbird/0.54.1?color=eb7a09)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)![pulls](https://img.shields.io/docker/pulls/11notes/netbird?color=2b75d6)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)[<img src="https://img.shields.io/github/issues/11notes/docker-NETBIRD?color=7842f5">](https://github.com/11notes/docker-NETBIRD/issues)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)![swiss_made](https://img.shields.io/badge/Swiss_Made-FFFFFF?labelColor=FF0000&logo=data:image/svg%2bxml;base64,PHN2ZyB2ZXJzaW9uPSIxIiB3aWR0aD0iNTEyIiBoZWlnaHQ9IjUxMiIgdmlld0JveD0iMCAwIDMyIDMyIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgogIDxyZWN0IHdpZHRoPSIzMiIgaGVpZ2h0PSIzMiIgZmlsbD0idHJhbnNwYXJlbnQiLz4KICA8cGF0aCBkPSJtMTMgNmg2djdoN3Y2aC03djdoLTZ2LTdoLTd2LTZoN3oiIGZpbGw9IiNmZmYiLz4KPC9zdmc+)

Run netbird rootless and distroless from a single image.

# INTRODUCTION 📢

NetBird combines a WireGuard-based overlay network with Zero Trust Network Access, providing a unified open source platform for reliable and secure connectivity. Create your own selfhosted ZTNA mesh network.

# SYNOPSIS 📖
**What can I do with this?** This image will run netbird from a single image (not multiple) [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) and [distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md) for more security. Due to the nature of a single image and not multiple, you see in the [compose.yaml](https://github.com/11notes/docker-netbird/blob/master/compose.yaml) example that an ```entrypoint:``` has been defined for each service. This image also needs some environment variables present in your **.env** file. This image's defaults (management.json) as well as the example **.env** are to be used with Keycloak as your IdP and Traefik as your reverse proxy. You can however provide your own **management.json** file and use any IdP you like and use a different reverse proxy.

The init binary **management** will replace all variables in the format ```${VARIABLE}``` with all environment variables present in the service.

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

If you value security, simplicity and optimizations to the extreme, then this image might be for you.

# COMPARISON 🏁
Below you find a comparison between this image and the most used or original one.

| **image** | 11notes/netbird | netbirdio/* |
| ---: | :---: | :---: |
| **image size on disk** | 44.6MB | 377.9MB |
| **process UID/GID** | 1000/1000 | 0/0 |
| **distroless?** | ✅ | ❌ |
| **rootless?** | ✅ | ❌ |

# VOLUMES 📁
* **/netbird/etc** - Directory of your management.json config
* **/netbird/var** - Directory of dynamic data from different init systems (relay, signal, management)

# EXAMPLE ENV FILE 📑
```ini
# postgres settings
POSTGRES_PASSWORD=

# netbird settings
NETBIRD_RELAY_SECRET=
NETBIRD_DATASTORE_ENCRYPTION_KEY=
NETBIRD_FQDN=netbird.domain.com

# Keycloak settings
KEYCLOAK_FQDN=keycloak.domain.com
KEYCLOAK_REALM=netbird
KEYCLOAK_CLIENT_SECRET=

# STUN/TURN configuration
STUN_FQDN_AND_PORT=turn.domain.com:5349
TURN_FQDN_AND_PORT=turn.domain.com:5349
TURN_SECRET=
```

# COMPOSE ✂️
```yaml
name: "netbird"

x-image-netbird: &image
  image: "11notes/netbird:0.54.1"
  read_only: true

services:
  db:
    image: "11notes/postgres:16"
    read_only: true
    environment:
      TZ: "Europe/Zurich"
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      # make a full and compressed database backup each day at 03:00
      POSTGRES_BACKUP_SCHEDULE: "0 3 * * *"
    volumes:
      - "db.etc:/postgres/etc"
      - "db.var:/postgres/var"
      - "db.backup:/postgres/backup"
    tmpfs:
      # needed for read-only
      - "/postgres/run:uid=1000,gid=1000"
      - "/postgres/log:uid=1000,gid=1000"
    networks:
      backend:
    restart: "always"

  dashboard:
    <<: *image
    environment:
      NETBIRD_MGMT_API_ENDPOINT: "https://${NETBIRD_FQDN}"
      NETBIRD_MGMT_GRPC_API_ENDPOINT: "https://${NETBIRD_FQDN}"
      AUTH_AUDIENCE: "netbird-client"
      AUTH_CLIENT_ID: "netbird-client"
      AUTH_CLIENT_SECRET: 
      AUTH_AUTHORITY: "https://${KEYCLOAK_FQDN}/realms/${KEYCLOAK_REALM}"
      USE_AUTH0: false
      AUTH_SUPPORTED_SCOPES: "openid"
      NETBIRD_TOKEN_SOURCE: "accessToken"
    entrypoint: ["/usr/local/bin/dashboard"]
    volumes:
      - "dashboard.var:/nginx/var"
    tmpfs:
      - "/nginx/cache:uid=1000,gid=1000"
      - "/nginx/run:uid=1000,gid=1000"
    networks:
      frontend:
    ports:
      - "3000:3000/tcp"
    healthcheck:
      test: ["CMD", "/usr/local/bin/curl", "-kILs", "--fail", "http://localhost:3000/ping"]
      interval: 5s
      timeout: 2s
      start_period: 5s
    restart: "always"

  management:
    depends_on:
      db:
        condition: "service_healthy"
        restart: true
    <<: *image
    env_file: '.env'
    environment:
      TZ: "Europe/Zurich"
      NETBIRD_STORE_ENGINE_POSTGRES_DSN: "host=db user=postgres password=${POSTGRES_PASSWORD} dbname=postgres port=5432"
      NB_ACTIVITY_EVENT_STORE_ENGINE: "postgres"
      NB_ACTIVITY_EVENT_POSTGRES_DSN: "host=db user=postgres password=${POSTGRES_PASSWORD} dbname=postgres port=5432"
    entrypoint: ["/usr/local/bin/management"]
    volumes:
      - "management.etc:/netbird/etc"
      - "management.var:/netbird/var"
    networks:
      frontend:
      backend:
    ports:
      - "3080:80/tcp"
      - "33073:33073/tcp"
    sysctls:
      net.ipv4.ip_unprivileged_port_start: 80
    healthcheck:
      test: ["CMD", "/usr/local/bin/curl", "-kILs", "--fail", "http://localhost:9090/metrics"]
      interval: 5s
      timeout: 2s
      start_period: 5s
    restart: "always"

  signal:
    <<: *image
    environment:
      TZ: "Europe/Zurich"
    entrypoint: ["/usr/local/bin/signal"]
    command: [
        "run",
        "--log-file", "console",
        "--log-level", "info"
      ]
    volumes:
      - "signal.var:/netbird/var"
    networks:
      frontend:
    ports:
      - "10000:10000/tcp"
    restart: "always"

  relay:
    <<: *image
    environment:
      TZ: "Europe/Zurich"
      NB_LISTEN_ADDRESS: ":33080"
      NB_EXPOSED_ADDRESS: "rels://${NETBIRD_FQDN}:443"
      NB_AUTH_SECRET: ${NETBIRD_RELAY_SECRET}
    entrypoint: ["/usr/local/bin/relay"]
    networks:
      frontend:
    ports:
      - "33080:33080/tcp"
    restart: "always"

volumes:
  management.etc:
  management.var:
  dashboard.var:
  signal.var:
  db.etc:
  db.var:
  db.backup:

networks:
  frontend:
  backend:
    internal: true
```

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

* [0.54.1](https://hub.docker.com/r/11notes/netbird/tags?name=0.54.1)

### There is no latest tag, what am I supposed to do about updates?
It is of my opinion that the ```:latest``` tag is dangerous. Many times, I’ve introduced **breaking** changes to my images. This would have messed up everything for some people. If you don’t want to change the tag to the latest [semver](https://semver.org/), simply use the short versions of [semver](https://semver.org/). Instead of using ```:0.54.1``` you can use ```:0``` or ```:0.54```. Since on each new version these tags are updated to the latest version of the software, using them is identical to using ```:latest``` but at least fixed to a major or minor version.

If you still insist on having the bleeding edge release of this app, simply use the ```:rolling``` tag, but be warned! You will get the latest version of the app instantly, regardless of breaking changes or security issues or what so ever. You do this at your own risk!

# REGISTRIES ☁️
```
docker pull 11notes/netbird:0.54.1
docker pull ghcr.io/11notes/netbird:0.54.1
docker pull quay.io/11notes/netbird:0.54.1
```

# SOURCE 💾
* [11notes/netbird](https://github.com/11notes/docker-NETBIRD)

# PARENT IMAGE 🏛️
> [!IMPORTANT]
>This image is not based on another image but uses [scratch](https://hub.docker.com/_/scratch) as the starting layer.
>The image consists of the following distroless layers that were added:
>* [11notes/distroless:curl](https://github.com/11notes/docker-distroless/blob/master/curl.dockerfile) - app to execute HTTP requests
>* 11notes/distroless:nginx

# BUILT WITH 🧰
* [netbirdio/netbird](https://github.com/netbirdio/netbird)

# GENERAL TIPS 📌
> [!TIP]
>* Use a reverse proxy like Traefik, Nginx, HAproxy to terminate TLS and to protect your endpoints
>* Use Let’s Encrypt DNS-01 challenge to obtain valid SSL certificates for your services

# CAUTION ⚠️
> [!CAUTION]
>* Because this image is distroless, it only works with PostgreSQL, **not SQLite**. The GeoLocation middleware is also disabled because of this!

# ElevenNotes™️
This image is provided to you at your own risk. Always make backups before updating an image to a different version. Check the [releases](https://github.com/11notes/docker-netbird/releases) for breaking changes. If you have any problems with using this image simply raise an [issue](https://github.com/11notes/docker-netbird/issues), thanks. If you have a question or inputs please create a new [discussion](https://github.com/11notes/docker-netbird/discussions) instead of an issue. You can find all my other repositories on [github](https://github.com/11notes?tab=repositories).

*created 13.08.2025, 09:51:28 (CET)*