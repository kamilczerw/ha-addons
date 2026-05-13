# Home Assistant add-on guide

## Add-on directory contract

Each add-on should live in its own top-level directory and usually contains:

```text
<addon>/
├── CHANGELOG.md
├── DOCS.md
├── Dockerfile
├── build.yaml
├── config.yaml
├── icon.png
├── logo.png
├── rootfs/
└── translations/
```

## `config.yaml`

When changing `config.yaml`:

- Keep `slug` stable after release.
- Bump `version` for releaseable add-on changes.
- Keep `options` and `schema` synchronized.
- Add or update `translations/*.yaml` for every exposed option.
- Keep `ingress_port`, Docker runtime port, service startup, and application server configuration aligned.
- Keep persistent data under `/data` unless migration work is explicitly planned.

Current Otter invariants:

- `slug`: `otter`
- `ingress`: enabled
- `ingress_port`: `42011`
- `ingress_entry`: `ui/`
- database path: `/data/budget.db`
- data map: writable `/data`
- package image: `ghcr.io/kamilczerw/otter`

## Dockerfile

The current Dockerfile is multi-stage:

1. Node frontend build.
2. Rust backend build.
3. Home Assistant base image runtime.

When editing it:

- Keep final runtime minimal.
- Keep `rootfs/` copied into the final image.
- Keep runtime environment values consistent with `config.yaml` and service startup.
- Be careful with architecture-specific build logic in `TARGETPLATFORM`.

## s6 service files

The service lives under `rootfs/etc/s6-overlay/s6-rc.d/otter/`.

- `type` should remain `longrun` for the server process.
- `run` should `exec` the application process so signal handling works correctly.
- The Otter service currently starts `/usr/bin/otter --config /data/options.json --static-dir /usr/share/otter/static`.

## Translations

- Keep translation keys aligned with `config.yaml` option names.
- Add entries to all supported languages when adding options.
- Prefer concise descriptions because Home Assistant displays these in configuration UI.

## Documentation and changelog

- Update `DOCS.md` for user-visible behavior, configuration, storage, or access changes.
- Update `CHANGELOG.md` for releaseable changes.
- Keep release notes user-focused rather than implementation-focused.
