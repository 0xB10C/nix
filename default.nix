{ pkgs ? import <nixpkgs> { } }:

{
  lib = import ./lib { inherit pkgs; };
  modules = import ./modules;
  overlays = import ./overlays;

  miningpool-observer = pkgs.callPackage ./pkgs/miningpool-observer { };
  github-metadata-mirror = pkgs.callPackage ./pkgs/github-metadata-mirror { };
  github-metadata-backup = pkgs.callPackage ./pkgs/github-metadata-backup { };
}
