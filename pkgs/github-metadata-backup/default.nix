{ stdenv, pkgs, lib, fetchFromGitHub, ... }:

pkgs.rustPlatform.buildRustPackage rec {
  name = "github-metadata-backup";
  version = "71a81242f1a006cd5f48d9607ee241c426edfa79";
  
  src = pkgs.fetchFromGitHub {
    owner = "0xb10c";
    repo = "github-metadata-backup";
    rev = version;
    sha256 = "sha256-gKesf9imC5lIeCu+LfOJ1LwSNkdJEevQ6dzFsElkF90=";
  };

  cargoHash = "sha256-AtxzqtrjksRLAjqRb/bctTtQoKxdTFfsvj5Zt7R0Qr0=";

  meta = {
    description = ''
      Download issues and pull-requests from the GitHub API and
      stores a backup as JSON files. Supports incremental updates.'';
    homepage = "https://github.com/0xb10c/github-metadata-backup";
    license = lib.licenses.mit;
  };
}
