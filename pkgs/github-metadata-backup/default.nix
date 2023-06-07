{ stdenv, pkgs, lib, fetchFromGitHub, ... }:

pkgs.rustPlatform.buildRustPackage rec {
  name = "github-metadata-backup";

  src = builtins.fetchGit {
    url = "git@github.com:0xB10C/github-metadata-backup.git";
    ref = "master";
    rev = "7505033e818896cd7258ef94d4f11e24b58227f9";
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
