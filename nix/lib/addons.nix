{ pkgs, lib }:
let
  repoRoot = ../..;
  repoSrc = lib.cleanSourceWith {
    src = repoRoot;
    filter =
      path: type:
      let
        rel = lib.removePrefix ((toString repoRoot) + "/") (toString path);
      in
      !(lib.hasPrefix ".git/" rel)
      && !(lib.hasInfix "/node_modules/" rel)
      && !(lib.hasInfix "/target/" rel)
      && !(lib.hasInfix "/result" rel);
  };

  copyAddon = addon: ''
    mkdir -p "$out"
    cp -R "${addon.path}" "$out/${addon.name}"
    chmod -R u+w "$out/${addon.name}"
  '';
in
{
  inherit repoRoot repoSrc;

  mkAddonPackage =
    addon:
    pkgs.stdenvNoCC.mkDerivation {
      pname = "ha-addon-${addon.name}";
      version = "local";
      dontUnpack = true;
      installPhase = copyAddon addon;
      meta = {
        description = "Home Assistant add-on package for ${addon.name}";
      };
    };

  mkAddonTarball =
    addon:
    pkgs.stdenvNoCC.mkDerivation {
      pname = "ha-addon-${addon.name}-tarball";
      version = "local";
      dontUnpack = true;
      nativeBuildInputs = [
        pkgs.gnutar
        pkgs.gzip
      ];
      installPhase = ''
        mkdir -p "$out"
        workdir="$(mktemp -d)"
        mkdir -p "$workdir/${addon.name}"
        cp -R "${addon.path}/." "$workdir/${addon.name}/"
        chmod -R u+w "$workdir"
        tar -C "$workdir" -czf "$out/${addon.name}.tar.gz" "${addon.name}"
      '';
      meta.description = "Tarball containing the ${addon.name} Home Assistant add-on directory";
    };

  mkRepositoryPackage =
    addons:
    pkgs.stdenvNoCC.mkDerivation {
      pname = "ha-addons-repository";
      version = "local";
      dontUnpack = true;
      installPhase = ''
        mkdir -p "$out"
        cp "${repoRoot}/repository.yaml" "$out/repository.yaml"
        ${lib.concatMapStringsSep "\n" (addon: ''
          cp -R "${addon.path}" "$out/${addon.name}"
          chmod -R u+w "$out/${addon.name}"
        '') addons}
      '';
      meta.description = "Packaged Home Assistant add-ons repository layout";
    };

  mkDockerBuildScript =
    addon:
    pkgs.writeShellApplication {
      name = "build-${addon.name}-docker";
      runtimeInputs = [ pkgs.docker ];
      text = ''
        set -euo pipefail
        tag="''${1:-${addon.image}:local}"
        docker build -f "${addon.relPath}/Dockerfile" -t "$tag" .
      '';
    };
}
