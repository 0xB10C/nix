{ stdenv, pkgs, lib, fetchFromGitHub, ... }:

stdenv.mkDerivation rec {
  name = "github-metadata-mirror";

  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "github-metadata-mirror";
    rev = "bee82cf1d92d3438f18a3c1b8dff0485ee2546c9";
    sha256 = "sha256-rx3PwMqwVdxIFbIuUlPvNzpYzgYWP9VzYg41NWWLa78=";
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
