{ pkgs ? import <nixpkgs> { } }:

{
  addrman-observer = pkgs.callPackage ./pkgs/addrman-observer { };
  ckpool = pkgs.callPackage ./pkgs/ckpool { };
  fork-observer = pkgs.callPackage ./pkgs/fork-observer { };
  github-metadata-backup = pkgs.callPackage ./pkgs/github-metadata-backup { };
  github-metadata-mirror = pkgs.callPackage ./pkgs/github-metadata-mirror { };
  stratum-observer = pkgs.callPackage ./pkgs/stratum-observer { };
  miningpool-observer = pkgs.callPackage ./pkgs/miningpool-observer { };
  peer-observer = pkgs.callPackage ./pkgs/peer-observer { };
}
