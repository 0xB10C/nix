{ stdenv, pkgs, lib, fetchFromGitHub, ... }:

pkgs.rustPlatform.buildRustPackage rec {
  name = "github-metadata-backup";
  pname = "github-metadata-backup";
  version = "3ce88b094a22bb6c2f8451a0275da04dc3b1135d";

  src = pkgs.fetchFromGitHub {
    owner = "0xb10c";
    repo = "github-metadata-backup";
    rev = version;
    sha256 = "sha256-0VgrENxMEGIuCeLM1MSfrFp5MGDx4GJph8TpDegYwMQ=";
  };

  cargoHash = "sha256-gG+7DJFgC4PvmeM8ccXCFBE4G+chRc7Uymrl2WsWrNU=";

  useFetchCargoVendor = true;

  meta = {
    description = ''
      Download issues and pull-requests from the GitHub API and
      stores a backup as JSON files. Supports incremental updates.'';
    homepage = "https://github.com/0xb10c/github-metadata-backup";
    license = lib.licenses.mit;
  };
}
