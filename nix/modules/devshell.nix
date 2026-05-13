{ pkgs }:
let
  python = pkgs.python3.withPackages (ps: [ ps.pyyaml ]);
in
{
  default = pkgs.mkShell {
    packages = with pkgs; [
      just
      jq
      yq-go
      yamllint
      shellcheck
      nixfmt
      nil
      docker-client
      python
    ];
  };
}
