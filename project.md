${{ title_caution }}
${{ github:> [!CAUTION] }}
${{ github:> }}Post tag 0.70.5 this image will now run the embedded IdP by default as well as using the unified management binary. If you were using an external IdP you can check the [guide](https://docs.netbird.io/selfhosted/migration/external-to-embedded-idp) from netbird what you can and need to do. This image is now also using the yml config and not the management.json anymore, please prepare your config accordingly!

${{ content_synopsis }} This image will run netbird from a single image (not multiple) [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) and [distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md) for more security and convenience. Since this image supports all netbird images as a single image, the dashboard image needs a custom command entry (see the compose [example](https://github.com/11notes/docker-netbird/blob/master/compose.yml#L41)). The init binary will also replace all environment variables present in the default.yml config file, in either the format ${VAR} or $VAR. The default config can be customized with environment variables, your own file or an [inline config](https://github.com/11notes/RTFM/blob/master/linux/container/image/11notes/inline-config.md), whatever you prefer. The default config is using the embedded IdP, you can then add your Keycloak or any other external IdP as well.


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
${{ github:> }}* ... this image creates random entries for unset keys and hashes from the default config
${{ github:> }}* ... this image supports [inline configs](https://github.com/11notes/RTFM/blob/master/linux/container/image/11notes/inline-config.md)

If you value security, simplicity and optimizations to the extreme, then this image might be for you.

${{ content_comparison }}

${{ title_volumes }}
* **${{ json_root }}/etc** - Directory of your config
* **${{ json_root }}/var** - Directory of dynamic data created by netbird

${{ title_config }}
```yaml
${{ include: ./rootfs/netbird/etc/default.yml }}
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
${{ github:> }}* Because this image is distroless, it only works with PostgreSQL/MySQL, **not SQLite**!