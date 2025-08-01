{ pkgs ? import <nixpkgs> { } }:

{
  addrman-observer = pkgs.callPackage ./pkgs/addrman-observer { };
  asmap-data = pkgs.callPackage ./pkgs/asmap-data { };
  bitcoind-tracing-v23 = pkgs.callPackage ./pkgs/bitcoind-tracing { version = "v23.2"; };
  bitcoind-tracing-v24 = pkgs.callPackage ./pkgs/bitcoind-tracing { version = "v24.2"; };
  bitcoind-tracing-v25 = pkgs.callPackage ./pkgs/bitcoind-tracing { version = "v25.2"; };
  bitcoind-tracing-v26 = pkgs.callPackage ./pkgs/bitcoind-tracing { version = "v26.2"; };
  bitcoind-tracing-v27 = pkgs.callPackage ./pkgs/bitcoind-tracing { version = "v27.2"; };
  bitcoind-tracing-v28 = pkgs.callPackage ./pkgs/bitcoind-tracing { version = "v28.0"; };
  bitcoind-tracing-v29 = pkgs.callPackage ./pkgs/bitcoind-tracing { version = "v29.0"; useCmake = true; };
  ckpool = pkgs.callPackage ./pkgs/ckpool { };
  fork-observer = pkgs.callPackage ./pkgs/fork-observer { };
  github-metadata-backup = pkgs.callPackage ./pkgs/github-metadata-backup { };
  github-metadata-mirror = pkgs.callPackage ./pkgs/github-metadata-mirror { };
  stratum-observer = pkgs.callPackage ./pkgs/stratum-observer { };
  miningpool-observer = pkgs.callPackage ./pkgs/miningpool-observer { };
  peer-observer = pkgs.callPackage ./pkgs/peer-observer { };
  mainnet-observer-backend = (pkgs.callPackage ./pkgs/mainnet-observer { }).backend;
}
