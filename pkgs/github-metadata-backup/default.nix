{ stdenv, pkgs, lib, fetchFromGitHub, ... }:

pkgs.rustPlatform.buildRustPackage rec {
  name = "github-metadata-backup";
  version = "6510e35ffe7ba973d367160f26c921fda3b1c8c0";
  
  src = pkgs.fetchFromGitHub {
    owner = "0xb10c";
    repo = "github-metadata-backup";
    rev = version;
    sha256 = "sha256-ftLevWbKEZ7WMnIdBQTFHVR+mogY4xVkis5bFJ68+XQ=";
  };

  cargoSha256 = "sha256-AIoEmsxADUDfnleJfzFxCsejh4ptbId8zlaEsrwN/Wg=";

  meta = {
    description = ''
      Download issues and pull-requests from the GitHub API and
      stores a backup as JSON files. Supports incremental updates.'';
    homepage = "https://github.com/0xb10c/github-metadata-backup";
    license = lib.licenses.mit;
  };
}
