${{ content_synopsis }} This image will run netbird from a single image (not multiple) [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) and [distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md) for more security. Due to the nature of a single image and not multiple, you see in the [compose.yml](https://github.com/11notes/docker-netbird/blob/master/compose.yml) example that an ```entrypoint:``` has been defined for each service. This image also needs some environment variables present in your **.env** file. This image's defaults (management.json) as well as the example **.env** are to be used with Keycloak as your IdP and Traefik as your reverse proxy. You can however provide your own **management.json** file and use any IdP you like and use a different reverse proxy.

The init binary **management** will replace all variables in the format ```${VARIABLE}``` with all environment variables present in the service.

${{ content_uvp }} Good question! Because ...

${{ github:> [!IMPORTANT] }}
${{ github:> }}* ... this image runs [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) as 1000:1000
${{ github:> }}* ... this image has no shell since it is [distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md)
${{ github:> }}* ... this image is auto updated to the latest version via CI/CD
${{ github:> }}* ... this image has a health check
${{ github:> }}* ... this image runs read-only
${{ github:> }}* ... this image is automatically scanned for CVEs before and after publishing
${{ github:> }}* ... this image is created via a secure and pinned CI/CD process
${{ github:> }}* ... this image is very small

If you value security, simplicity and optimizations to the extreme, then this image might be for you.

${{ content_comparison }}

${{ title_volumes }}
* **${{ json_root }}/etc** - Directory of your management.json config
* **${{ json_root }}/var** - Directory of dynamic data from different init systems (relay, signal, management)

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

${{ content_compose }}

${{ content_defaults }}

${{ content_environment }}

${{ content_source }}

${{ content_parent }}

${{ content_built }}

${{ content_tips }}

${{ title_caution }}
${{ github:> [!CAUTION] }}
${{ github:> }}* Because this image is distroless, it only works with PostgreSQL, **not SQLite**!