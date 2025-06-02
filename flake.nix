{
  description = "My personal NUR repository";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  outputs =
    { self, nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "i686-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "armv6l-linux"
        "armv7l-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
      nixos-lib = import (nixpkgs + "/nixos/lib") { };
      mkTest =
        imports: system:
        nixos-lib.runTest {
          inherit imports;
          hostPkgs = import nixpkgs { inherit system; };
        };
    in
    {

      packages = forAllSystems (system:
        import ./default.nix { pkgs = import nixpkgs { inherit system; }; } // {
          # this is only used to test buidling the frontend with the
          # lib function. Using this directly does not make sense. Use the
          # mkMainnetObserverFrontend function
          mainnet-observer-frontend-placeholder = self.lib.${system}.mkMainnetObserverFrontend {
            title = "TITLE_PLACEHOLDER";
            baseURL = "URL_PLACEHOLDER";
            htmlTopRight = "TOP-RIGHT PLACEHOLDER";
            htmlBottomRight = "BOTTOM-RIGHT PLACEHOLDER";
          };
        }
      );

      lib = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in {
          mkMainnetObserverFrontend = { title, baseURL, htmlTopRight, htmlBottomRight }:
            (pkgs.callPackage ./pkgs/mainnet-observer { }).frontend {
              inherit title baseURL htmlTopRight htmlBottomRight;
            };
        }
      );

      nixosModules = {
        default = import ./modules;
      };

      checks = forAllSystems (system: {
        asmap-data = mkTest [ ./tests/asmap-data.nix ] system;
        ckpool = mkTest [ ./tests/ckpool.nix ] system;
        stratum-observer = mkTest [ ./tests/stratum-observer.nix ] system;
        addrman-observer = mkTest [ ./tests/addrman-observer.nix ] system;
        peer-observer = mkTest [ ./tests/peer-observer.nix ] system;
        mainnet-observer = mkTest [ ./tests/mainnet-observer.nix ] system;
        fork-observer = mkTest [ ./tests/fork-observer.nix ] system;
        miningpool-observer = mkTest [ ./tests/miningpool-observer.nix ] system;
      });

    };
}
