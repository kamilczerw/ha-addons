# Validation checklist

Run the checks that fit the change. Do not report unchecked items as complete.

## Repository-level documentation changes

- Confirm all Markdown links resolve.
- Confirm guidance does not mention files that are absent unless clearly described as a future convention.
- Check spelling of paths and Home Assistant terms.

## YAML changes

Use one of these if available:

```bash
python - <<'PY'
import pathlib, yaml
for path in pathlib.Path('.').rglob('*.yaml'):
    with path.open() as f:
        yaml.safe_load(f)
    print(path)
PY
```

If `PyYAML` is not installed, use Ruby or another available YAML parser:

```bash
ruby -e 'require "yaml"; Dir["**/*.yaml"].each { |f| YAML.load_file(f); puts f }'
```

## Home Assistant add-on metadata checks

For each changed add-on:

- `config.yaml` parses as YAML.
- `options` keys match `schema` keys unless intentionally hidden.
- Each user-facing option has translations in every language under `translations/`.
- Ports and ingress settings align with Docker/runtime configuration.
- Persistent data stays under `/data` unless migration is included.

## Docker-related checks

If Docker is available and the build context is complete, run a build for the changed add-on. For example:

```bash
docker build -f otter/Dockerfile otter
```

If the Dockerfile expects files that are not in this repository, document that limitation in the final response.

## Shell/service checks

For changed shell scripts:

```bash
bash -n path/to/script
```

For executable service scripts, ensure they retain executable permissions.
