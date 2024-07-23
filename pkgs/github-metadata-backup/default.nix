{ stdenv, pkgs, lib, fetchFromGitHub, ... }:

pkgs.rustPlatform.buildRustPackage rec {
  name = "github-metadata-backup";
  version = "953158b9b432f2d60e25ef4a2bd93f943739c7b6";
  
  src = pkgs.fetchFromGitHub {
    owner = "0xb10c";
    repo = "github-metadata-backup";
    rev = version;
    sha256 = "sha256-l0bfeCKOl3JiaWwjVhT5J81fpBAJH/CDHFBfvCDoRvs=";
  };

  cargoSha256 = "sha256-m0x9EohDfKuWeF2dgVCKX/7wbdyPDXNHPToKcHgfagQ=";

  meta = {
    description = ''
      Download issues and pull-requests from the GitHub API and
      stores a backup as JSON files. Supports incremental updates.'';
    homepage = "https://github.com/0xb10c/github-metadata-backup";
    license = lib.licenses.mit;
  };
}
