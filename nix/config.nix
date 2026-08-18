{ lib }:
{
  # Register Home Assistant add-ons here. Keep relPath stable because it is used
  # by Nix package names, validation checks, and local Docker build helpers.
  #
  # buildInRepo: true when the Dockerfile's build context is fully self-contained
  # in this repo (CI may build/push it here); false when the image is built and
  # pushed by an external source repo and this repo only tracks its version.
  #
  # sourceRepo: where to check for the latest upstream release. A bare
  # "owner/repo" means GitHub; a "codeberg.org/owner/repo" prefix means
  # Codeberg. For buildInRepo addons this string also doubles as the image
  # reference (minus tag) pinned in Dockerfile/build.yaml, so the
  # update-addon-version workflow can bump both from one field.
  addons = [
    {
      name = "otter";
      relPath = "otter";
      path = ../otter;
      image = "ghcr.io/kamilczerw/otter";
      sourceRepo = "kamilczerw/otter";
      supportedArchitectures = [ "amd64" ];
      buildInRepo = false;
    }
    {
      name = "forgejo";
      relPath = "forgejo";
      path = ../forgejo;
      image = "ghcr.io/kamilczerw/forgejo";
      sourceRepo = "codeberg.org/forgejo/forgejo";
      supportedArchitectures = [ "amd64" ];
      buildInRepo = true;
    }
  ];
}
