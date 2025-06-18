${{ content_synopsis }} This image will run netbird from a single image (not multiple) rootless and distroless for more security. Due to the nature of a single image and not multiple, you see in the [compose.yaml](https://github.com/11notes/docker-netbird/blob/master/compose.yaml) example that an ```entrypoint:``` has been defined. This image also needs some environment variables present in your **.env** file. This image's defaults (management.json) as well as the example **.env** are to be used with Keycloak as your IdP. You can however provide your own **management.json** file and use any IdP you like.

${{ github:> [!IMPORTANT] }}
${{ github:> }}* This image runs as 1000:1000 by default, most other images run everything as root
${{ github:> }}* This image has no shell since it is distroless, most other images run on a distro like Debian or Alpine with full shell access (security)
${{ github:> }}* This image does not ship with any critical or high rated CVE and is automatically maintained via CI/CD, most other images mostly have no CVE scanning or code quality tools in place
${{ github:> }}* This image is created via a secure, pinned CI/CD process and immune to upstream attacks, most other images have upstream dependencies that can be exploited
${{ github:> }}* This image works as read-only, most other images need to write files to the image filesystem
${{ github:> }}* This image is a lot smaller than most other images

If you value security, simplicity and the ability to interact with the maintainer and developer of an image. Using my images is a great start in that direction.

# COMPARISON 🏁
Below you find a comparison between this image and the most used or original one.

| **image** | 11notes/netbird | netbirdio/* |
| ---: | :---: | :---: |
| **image size on disk** | 44.6MB | 377.9MB |
| **process UID/GID** | 1000/1000 | 0/0 |
| **distroless?** | ✅ | ❌ |
| **rootless?** | ✅ | ❌ |

${{ title_volumes }}
* **${{ json_root }}/etc** - Directory of your management.json config
* **${{ json_root }}/var** - Directory of dynamic data from differnet init systems (relay, signal, management)

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
${{ github:> }}* Because this image is distroless, it only works with PostgreSQL, not SQLite. The GeoLocation middleware is also disabled because of this!