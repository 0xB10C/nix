{ pkgs ? import <nixpkgs> { } }:

{
  lib = import ./lib { inherit pkgs; };
  modules = import ./modules;
  overlays = import ./overlays;

  miningpool-observer = pkgs.callPackage ./pkgs/miningpool-observer { };
  fork-observer = pkgs.callPackage ./pkgs/fork-observer { };
}
