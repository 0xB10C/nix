{
  description = "My personal NUR repository";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

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

      packages = forAllSystems (
        system: import ./default.nix { pkgs = import nixpkgs { inherit system; }; }
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
        transactionfee-info = mkTest [ ./tests/transactionfee-info.nix ] system;
        fork-observer = mkTest [ ./tests/fork-observer.nix ] system;
        miningpool-observer = mkTest [ ./tests/miningpool-observer.nix ] system;
      });

    };
}
