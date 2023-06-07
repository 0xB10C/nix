{ stdenv, pkgs, lib, fetchFromGitHub, ... }:

pkgs.rustPlatform.buildRustPackage rec {
  name = "github-metadata-backup";

  src = pkgs.fetchFromGitHub {
    owner = "0xb10c";
    repo = "github-metadata-backup";
    rev = "7505033e818896cd7258ef94d4f11e24b58227f9";
    sha256 = "sha256-dkmyd3mlUkfsEdytDdo0Kzi2BN4suXPqquCke3q90gg=";
  };

  cargoSha256 = "sha256-OWqL6plXL2zdHNR8w1DMMhVxUph5qeXUHLahWm2NosA=";

  meta = {
    description = ''
      Download issues and pull-requests from the GitHub API and
      stores a backup as JSON files. Supports incremental updates.'';
    homepage = "https://github.com/0xb10c/github-metadata-backup";
    license = lib.licenses.mit;
  };
}
