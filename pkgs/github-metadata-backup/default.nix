{ stdenv, pkgs, lib, fetchFromGitHub, ... }:

pkgs.rustPlatform.buildRustPackage rec {
  name = "github-metadata-backup";
  version = "7bea8fe080920df00751c7601dd95205debbabad";
  
  src = pkgs.fetchFromGitHub {
    owner = "0xb10c";
    repo = "github-metadata-backup";
    rev = version;
    sha256 = "sha256-p/pKlpIwIgNZ4iAC6S3II83eQPPxbmKdPe5p4emo0Dg=";
  };

  cargoHash = "sha256-zBJWjPA+b/7/BMeXkADzCbEgNbdbBa7LZWLtIff04nU=";

  meta = {
    description = ''
      Download issues and pull-requests from the GitHub API and
      stores a backup as JSON files. Supports incremental updates.'';
    homepage = "https://github.com/0xb10c/github-metadata-backup";
    license = lib.licenses.mit;
  };
}
