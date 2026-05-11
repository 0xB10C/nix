{ stdenv, pkgs, lib, fetchFromGitHub, ... }:

pkgs.rustPlatform.buildRustPackage rec {
  name = "github-metadata-backup";
  pname = "github-metadata-backup";
  version = "29c8f342a35b1d1ecb8318797c71c4c1a980c1a3";

  src = pkgs.fetchFromGitHub {
    owner = "0xb10c";
    repo = "github-metadata-backup";
    rev = version;
    sha256 = "sha256-8hDQuMnDmyn+lFg/6kx/NGNkQVgjiHRW0gpeKijFhrk=";
  };

  cargoHash = "sha256-7u39nIpUp+zKOv0P/ZJ4H9Z4WMEp+X2tBWVxNI5k/JA=";

  meta = {
    description = ''
      Download issues and pull-requests from the GitHub API and
      stores a backup as JSON files. Supports incremental updates.'';
    homepage = "https://github.com/0xb10c/github-metadata-backup";
    license = lib.licenses.mit;
  };
}
