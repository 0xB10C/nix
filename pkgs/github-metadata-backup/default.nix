{ stdenv, pkgs, lib, fetchFromGitHub, ... }:

pkgs.rustPlatform.buildRustPackage rec {
  name = "github-metadata-backup";
  version = "b5adba1de2794a1a7c362ad927b8b30502aac3bf";

  src = pkgs.fetchFromGitHub {
    owner = "0xb10c";
    repo = "github-metadata-backup";
    rev = version;
    sha256 = "sha256-8aoK1pbqLc5BiJrW6kvdyjNue5I74okrnpIp1uIrQi4=";
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
