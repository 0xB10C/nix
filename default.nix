{ pkgs ? import <nixpkgs> { } }:
let
  # ckpool uses clock_nanosleep (librt) and /proc/cpuinfo, both Linux-only.
  linuxOnlyPkgs = pkgs.lib.attrsets.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    ckpool = pkgs.callPackage ./pkgs/ckpool { };
  };
  allPlatformsPkgs = rec {
    addrman-observer = pkgs.callPackage ./pkgs/addrman-observer { };
    asmap-data = pkgs.callPackage ./pkgs/asmap-data { };
    bitcoind-tracing-v28 = pkgs.callPackage ./pkgs/bitcoind-tracing { version = "v28.0"; };
    bitcoind-tracing-v29 = pkgs.callPackage ./pkgs/bitcoind-tracing { version = "v29.0"; useCmake = true; };
    bitcoind-tracing-v30 = pkgs.callPackage ./pkgs/bitcoind-tracing { version = "v30.0"; useCmake = true; };
    bitcoind-tracing-v31 = pkgs.callPackage ./pkgs/bitcoind-tracing { version = "v31.0"; useCmake = true; };
    bitcoind-tracing-latest = bitcoind-tracing-v31;
    discourse-archive = pkgs.callPackage ./pkgs/discourse-archive { };
    fork-observer = pkgs.callPackage ./pkgs/fork-observer { };
    github-metadata-backup = pkgs.callPackage ./pkgs/github-metadata-backup { };
    github-metadata-mirror = pkgs.callPackage ./pkgs/github-metadata-mirror { };
    mainnet-observer-backend = (pkgs.callPackage ./pkgs/mainnet-observer { }).backend;
    miningpool-observer = pkgs.callPackage ./pkgs/miningpool-observer { };
    peer-observer = pkgs.callPackage ./pkgs/peer-observer { };
    stratum-observer = pkgs.callPackage ./pkgs/stratum-observer { };
  };
in
  allPlatformsPkgs // linuxOnlyPkgs
