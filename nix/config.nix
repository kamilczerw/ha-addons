{ lib }:
{
  # Register Home Assistant add-ons here. Keep relPath stable because it is used
  # by Nix package names, validation checks, and local Docker build helpers.
  addons = [
    {
      name = "otter";
      relPath = "otter";
      path = ../otter;
      image = "ghcr.io/kamilczerw/otter";
      supportedArchitectures = [ "amd64" ];
    }
  ];
}
