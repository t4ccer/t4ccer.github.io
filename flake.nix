{
  description = "t4ccer's website";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable-small";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    git-hooks-nix = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.git-hooks-nix.flakeModule
      ];

      systems = inputs.nixpkgs.lib.systems.flakeExposed;

      perSystem =
        {
          config,
          pkgs,
          lib,
          system,
          ...
        }:
        {
          pre-commit.settings = {
            src = ./.;
            hooks = {
              nixfmt.enable = true;
              typos = {
                enable = true;
                excludes = [ "cabal.project.freeze" ];
                settings.ignored-words = [ ];
              };
              fourmolu.enable = true;
              trim-trailing-whitespace.enable = true;
            };
          };

          devShells.default = pkgs.mkShell {
            shellHook = ''
              ${config.pre-commit.shellHook}
            '';

            buildInputs = [
              pkgs.zlib
            ];

            nativeBuildInputs = [
              pkgs.ghc
              pkgs.haskell-language-server
              pkgs.cabal-install
              pkgs.miniserve
            ];
          };
        };
    };
}
