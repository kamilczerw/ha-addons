# Repository overview

This is Kamil's Home Assistant add-ons repository.

## Current layout

```text
.
├── AGENTS.md
├── README.md
├── repository.yaml
└── otter/
    ├── CHANGELOG.md
    ├── DOCS.md
    ├── Dockerfile
    ├── build.yaml
    ├── config.yaml
    ├── icon.png
    ├── logo.png
    ├── rootfs/
    │   └── etc/s6-overlay/s6-rc.d/
    └── translations/
        ├── en.yaml
        └── pl.yaml
```

## Repository role

- `repository.yaml` declares the Home Assistant add-on repository metadata.
- Each top-level add-on directory, such as `otter/`, is an independently versioned Home Assistant add-on.
- The Otter application source is not vendored here. The add-on image expects `frontend/` and `backend/` build contexts when building the Otter image, and the add-on metadata points to `ghcr.io/kamilczerw/otter`.

## Important files

- `otter/config.yaml`: Home Assistant add-on manifest. Treat this as the source of truth for slug, version, ingress settings, options, schema, persistent data mapping, exposed ports, and environment defaults.
- `otter/build.yaml`: Home Assistant builder base-image selection.
- `otter/Dockerfile`: image build for frontend, backend, and final HA add-on runtime.
- `otter/rootfs/`: files copied into the add-on image. Currently contains the s6 service definition for starting Otter.
- `otter/translations/`: option labels/descriptions shown in Home Assistant.
- `otter/DOCS.md`: user-facing add-on documentation.
- `otter/CHANGELOG.md`: release notes for add-on updates.
- `flake.nix` and `nix/`: Nix development shell, add-on metadata checks, packaging outputs, tarball outputs, and Docker build helper scripts.

## Boundaries

- Do not assume application-level Otter code exists in this repository unless it is added later.
- Keep add-on packaging concerns here: HA metadata, container integration, service startup, translations, docs, changelog, and release wiring.
- If adding more add-ons, create one top-level directory per add-on and add local guidance only when the add-on diverges from shared conventions.
