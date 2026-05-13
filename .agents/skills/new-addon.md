# New Addon skill

Use this skill when creating boilerplate for a new Home Assistant add-on in this repository.

## Goal

Create a new top-level add-on directory that is immediately visible to Home Assistant tooling and wrapped by Nix for local validation, packaging, and Docker build helper generation.

## Inputs to gather

- Add-on slug, for example `my-addon`.
- Display name and short description.
- Container image name, usually `ghcr.io/kamilczerw/<slug>`.
- Supported Home Assistant architectures, for example `[ "amd64" ]`.
- Whether ingress is needed, and if so the internal ingress port and entry path.
- Runtime command and any s6 service requirements.
- Persistent data requirements under `/data`.
- User-facing options, schema, and translations.

## Boilerplate directory

Create:

```text
<slug>/
├── CHANGELOG.md
├── DOCS.md
├── Dockerfile
├── build.yaml
├── config.yaml
├── rootfs/
│   └── etc/s6-overlay/s6-rc.d/
│       ├── <slug>/
│       │   ├── run
│       │   └── type
│       └── user/contents.d/<slug>
└── translations/
    └── en.yaml
```

Add `icon.png` and `logo.png` when final artwork is available.

## Nix registration

Add the add-on to `nix/config.nix`:

```nix
{
  name = "<slug>";
  relPath = "<slug>";
  path = ../<slug>;
  image = "ghcr.io/kamilczerw/<slug>";
  supportedArchitectures = [ "amd64" ];
}
```

After registration, the shared Nix wrapper automatically exposes:

- `nix build .#addon-<slug>`: package the add-on directory.
- `nix build .#addon-<slug>-tarball`: produce `<slug>.tar.gz`.
- `nix run .#build-<slug>-docker -- [tag]`: build the Docker image using `<slug>/Dockerfile`.
- `nix flake check`: run repository-wide YAML, metadata, shell, and Nix formatting checks.

## Required consistency rules

- `config.yaml.slug` must match `nix/config.nix` `name`.
- `config.yaml.image` must match `nix/config.nix` `image`.
- `config.yaml.arch` must match `supportedArchitectures`.
- `options` and `schema` keys must match.
- Every option must have translations in every `translations/*.yaml` file.
- Service `run` scripts must have a shebang and pass `bash -n`.
- Keep persistent state under `/data`.

## Validation loop

1. Run `nix fmt` or `nixfmt` on Nix files.
2. Run `nix flake check`.
3. Run `nix build .#addon-<slug>`.
4. Run `nix build .#addon-<slug>-tarball`.
5. If Docker context is complete, run `nix run .#build-<slug>-docker -- ghcr.io/kamilczerw/<slug>:local`.
6. Update `DOCS.md`, `CHANGELOG.md`, and translations before reporting completion.
