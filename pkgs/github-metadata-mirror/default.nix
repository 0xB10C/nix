{ stdenv, pkgs, lib, fetchFromGitHub, ... }:

stdenv.mkDerivation rec {
  name = "github-metadata-mirror";

  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "github-metadata-mirror";
    rev = "75c94609904694909919a0df70afd50a6f2fed36";
    sha256 = "sha256-aIbY2x2fd2s7hPf4cT8B7UbERuVPMWmp9EF0Wlry/m0=";
  };

  installPhase = ''
    cp -r $src $out
  '';

  meta = {
    description = "A GitHub metadata mirror";
    longDescription = ''
      This tool allows to generate a static HTML GitHub metadata mirror for
      archiving GitHub comments and reviews on GitHub issues and pull requests.
      Together with hugo and a GitHub metadata backup static HTML pages are
      generated for each issue and pull-request.
    '';
    homepage = "https://github.com/0xb10c/github-metadata-mirror";
    license = lib.licenses.mit;
  };
}
