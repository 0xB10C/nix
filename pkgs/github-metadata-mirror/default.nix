{ stdenv, pkgs, lib, fetchFromGitHub, ... }:

stdenv.mkDerivation rec {
  name = "github-metadata-mirror";
  pname = "github-metadata-mirror";
  version = "e9e88442fcb465cc2d95a0388fcb26fda6aa0051";
  
  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "github-metadata-mirror";
    rev = version;
    sha256 = "sha256-gIfX/BluATT46EBVWO3RKIWJ5+rDD+lAV4lRciuXcYI=";
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
