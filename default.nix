{ pkgs ? import <nixpkgs> { } }:

{
  lib = import ./lib { inherit pkgs; };
  modules = import ./modules;
  overlays = import ./overlays;

  fork-observer = pkgs.callPackage ./pkgs/fork-observer { };
  github-metadata-backup = pkgs.callPackage ./pkgs/github-metadata-backup { };
  github-metadata-mirror = pkgs.callPackage ./pkgs/github-metadata-mirror { };
  miningpool-observer = pkgs.callPackage ./pkgs/miningpool-observer { };
}
