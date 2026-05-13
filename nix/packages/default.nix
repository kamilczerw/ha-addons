{
  pkgs,
  lib,
  config,
  addonLib,
}:
let
  addonPackages = addon: [
    {
      name = "addon-${addon.name}";
      value = addonLib.mkAddonPackage addon;
    }
    {
      name = "addon-${addon.name}-tarball";
      value = addonLib.mkAddonTarball addon;
    }
    {
      name = "build-${addon.name}-docker";
      value = addonLib.mkDockerBuildScript addon;
    }
  ];
in
builtins.listToAttrs (lib.flatten (map addonPackages config.addons))
// {
  default = addonLib.mkRepositoryPackage config.addons;
  repository = addonLib.mkRepositoryPackage config.addons;
}
