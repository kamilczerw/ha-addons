{
  description = "Kamil's Home Assistant Add-ons";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;

        config = import ./nix/config.nix { inherit lib; };
        addonLib = import ./nix/lib/addons.nix { inherit pkgs lib; };

        packages = import ./nix/packages {
          inherit
            pkgs
            lib
            config
            addonLib
            ;
        };

        checks = import ./nix/modules/checks.nix {
          inherit
            pkgs
            lib
            config
            addonLib
            ;
        };

        devShells = import ./nix/modules/devshell.nix { inherit pkgs; };
      in
      {
        inherit packages checks devShells;
      }
    );
}
