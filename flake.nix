{
  description = "Basic flake that provides proxytunnel as a package or as a binary in a nix shell";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      # TODO: Add support for more systems once checked.
      # TODO: Maybe add configuration options for toggling Makefile {C/LD/OPT}FLAGS
      systems = ["x86_64-linux"];

      imports = [inputs.flake-parts.flakeModules.easyOverlay];

      perSystem = {
        config,
        pkgs,
        ...
      }: {
        overlayAttrs = {
          inherit (config.packages) proxytunnel;
          enableSSL = true;
        };

        packages.proxytunnel = pkgs.stdenv.mkDerivation {
          pname = "proxytunnel";
          version = "1.12.3";
          src = ./.;

          nativeBuildInputs = [pkgs.gnumake];
          buildInputs = [pkgs.openssl];

          buildPhase = ''
            make
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp ./proxytunnel $out/bin/${
              if config.overlayAttrs.enableSSL
              then "proxytunnel-yes-ssl"
              else "proxytunnel-no-ssl"
            }
          '';
        };

        packages.default = config.packages.proxytunnel;

        devShells.default = pkgs.mkShell {
          packages = [config.packages.default];
        };
      };
    };
}
