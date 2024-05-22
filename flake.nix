{
  description = "My personal NUR repository";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/24.05";
  
  outputs = { self, nixpkgs, ... }:
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
    in
    {
    
      packages = forAllSystems (system: import ./default.nix {
          pkgs = import nixpkgs { inherit system; };
      });
      
      nixosModules = {
        default = import ./modules;
      };
      
      checks = forAllSystems (system: {
        stratum-observer = nixos-lib.runTest {
          imports = [ 
            ./tests/stratum-observer.nix 
          ];
          hostPkgs = import nixpkgs { inherit system; };
        };
      });
      
    };
}
