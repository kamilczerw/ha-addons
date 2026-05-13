{
  pkgs,
  lib,
  config,
  addonLib,
}:
let
  python = pkgs.python3.withPackages (ps: [ ps.pyyaml ]);
  repoSrc = addonLib.repoSrc;
  addonData = builtins.toJSON (
    map (addon: {
      inherit (addon)
        name
        relPath
        image
        supportedArchitectures
        ;
    }) config.addons
  );
in
{
  yaml = pkgs.runCommand "ha-addons-yaml-check" { nativeBuildInputs = [ python ]; } ''
    cd ${repoSrc}
    python - <<'PY'
    from pathlib import Path
    import yaml

    for path in sorted(Path('.').rglob('*.yaml')):
        with path.open() as handle:
            yaml.safe_load(handle)
        print(path)
    PY
    touch $out
  '';

  addonMetadata =
    pkgs.runCommand "ha-addons-metadata-check"
      {
        nativeBuildInputs = [ python ];
        ADDONS_JSON = addonData;
      }
      ''
        cd ${repoSrc}
        python - <<'PY'
        from pathlib import Path
        import json
        import os
        import sys
        import yaml

        addons = json.loads(os.environ['ADDONS_JSON'])
        errors = []

        def load_yaml(path):
            with Path(path).open() as handle:
                return yaml.safe_load(handle) or {}

        repo = load_yaml('repository.yaml')
        for key in ['name', 'url', 'maintainer']:
            if key not in repo:
                errors.append(f'repository.yaml missing required key: {key}')

        for addon in addons:
            root = Path(addon['relPath'])
            config_path = root / 'config.yaml'
            if not config_path.exists():
                errors.append(f"{addon['name']}: missing config.yaml")
                continue

            cfg = load_yaml(config_path)
            for key in ['name', 'version', 'slug', 'description', 'arch']:
                if key not in cfg:
                    errors.append(f"{addon['name']}: config.yaml missing {key}")

            if cfg.get('slug') != addon['name']:
                errors.append(f"{addon['name']}: slug should match nix config name")

            if cfg.get('image') != addon['image']:
                errors.append(f"{addon['name']}: image differs between config.yaml and nix/config.nix")

            if sorted(cfg.get('arch', [])) != sorted(addon.get('supportedArchitectures', [])):
                errors.append(f"{addon['name']}: arch differs between config.yaml and nix/config.nix")

            options = set((cfg.get('options') or {}).keys())
            schema = set((cfg.get('schema') or {}).keys())
            if options != schema:
                errors.append(f"{addon['name']}: options and schema keys differ: options={sorted(options)} schema={sorted(schema)}")

            translation_dir = root / 'translations'
            if options and not translation_dir.exists():
                errors.append(f"{addon['name']}: options exist but translations directory is missing")
            for translation_path in sorted(translation_dir.glob('*.yaml')):
                translations = load_yaml(translation_path)
                translated = set((translations.get('configuration') or {}).keys())
                missing = options - translated
                if missing:
                    errors.append(f"{addon['name']}: {translation_path} missing translations for {sorted(missing)}")

            if (root / 'rootfs/etc/s6-overlay/s6-rc.d').exists():
                for run_script in (root / 'rootfs/etc/s6-overlay/s6-rc.d').glob('*/run'):
                    if not run_script.read_text().startswith('#!'):
                        errors.append(f"{addon['name']}: {run_script} is missing a shebang")

        if errors:
            print('\n'.join(errors), file=sys.stderr)
            sys.exit(1)
        print(f'Validated {len(addons)} add-on(s)')
        PY
        touch $out
      '';

  shellScripts =
    pkgs.runCommand "ha-addons-shell-check"
      {
        nativeBuildInputs = [
          pkgs.bash
          pkgs.shellcheck
        ];
      }
      ''
        cd ${repoSrc}
        while IFS= read -r script; do
          echo "checking $script"
          bash -n "$script"
          shellcheck -s bash -S warning "$script"
        done < <(find . -path '*/rootfs/etc/s6-overlay/s6-rc.d/*/run' -type f | sort)
        touch $out
      '';

  nixfmt = pkgs.runCommand "ha-addons-nixfmt-check" { nativeBuildInputs = [ pkgs.nixfmt ]; } ''
    cd ${repoSrc}
    find flake.nix nix -name '*.nix' -print0 | xargs -0 nixfmt --check
    touch $out
  '';
}
