{ pkgs ? import <nixpkgs> { } }:

let
  default-mainnet-observer-frontend = title: baseURL: htmlTopRight: htmlBottomRight: (pkgs.callPackage ./pkgs/mainnet-observer { }).frontend { inherit title baseURL htmlTopRight htmlBottomRight; };
in
{
  addrman-observer = pkgs.callPackage ./pkgs/addrman-observer { };
  asmap-data = pkgs.callPackage ./pkgs/asmap-data { };
  bitcoind-tracing-v23 = pkgs.callPackage ./pkgs/bitcoind-tracing { version = "v23.2"; };
  bitcoind-tracing-v24 = pkgs.callPackage ./pkgs/bitcoind-tracing { version = "v24.2"; };
  bitcoind-tracing-v25 = pkgs.callPackage ./pkgs/bitcoind-tracing { version = "v25.2"; };
  bitcoind-tracing-v26 = pkgs.callPackage ./pkgs/bitcoind-tracing { version = "v26.2"; };
  bitcoind-tracing-v27 = pkgs.callPackage ./pkgs/bitcoind-tracing { version = "v27.2"; };
  bitcoind-tracing-v28 = pkgs.callPackage ./pkgs/bitcoind-tracing { version = "v28.0"; };
  ckpool = pkgs.callPackage ./pkgs/ckpool { };
  fork-observer = pkgs.callPackage ./pkgs/fork-observer { };
  github-metadata-backup = pkgs.callPackage ./pkgs/github-metadata-backup { };
  github-metadata-mirror = pkgs.callPackage ./pkgs/github-metadata-mirror { };
  stratum-observer = pkgs.callPackage ./pkgs/stratum-observer { };
  miningpool-observer = pkgs.callPackage ./pkgs/miningpool-observer { };
  peer-observer = pkgs.callPackage ./pkgs/peer-observer { };
  mainnet-observer-backend = (pkgs.callPackage ./pkgs/mainnet-observer { }).backend;

  # this is the frontend configured with placeholders. You might want to configure it differently.
  default-mainnet-observer-frontend = (pkgs.callPackage ./pkgs/mainnet-observer { }).frontend { title = "TITLE_PLACEHOLDER"; baseURL = "URL_PLACEHOLDER"; htmlTopRight = "TOP-RIGHT PLACEHOLDER"; htmlBottomRight = "BOTTOM-RIGHT PLACEHOLDER"; };
}
