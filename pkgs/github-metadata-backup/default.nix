{ stdenv, pkgs, lib, fetchFromGitHub, ... }:

pkgs.rustPlatform.buildRustPackage rec {
  name = "github-metadata-backup";
  version = "7ba9de2d3082e76a1a9dab711fc3b6df71ce2246";

  src = pkgs.fetchFromGitHub {
    owner = "0xb10c";
    repo = "github-metadata-backup";
    rev = version;
    sha256 = "sha256-nYIZpARfvrh0NDu1ix4+jokXQqjGCpLESCz96KM83O0=";
  };

  cargoHash = "sha256-JHW6Gfs4axnYC8BMcV8nGOqTnWyln669kS4SpVPFLFw=";

  useFetchCargoVendor = true;

  meta = {
    description = ''
      Download issues and pull-requests from the GitHub API and
      stores a backup as JSON files. Supports incremental updates.'';
    homepage = "https://github.com/0xb10c/github-metadata-backup";
    license = lib.licenses.mit;
  };
}
