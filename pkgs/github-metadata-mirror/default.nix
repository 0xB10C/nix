{ stdenv, pkgs, lib, fetchFromGitHub, ... }:

stdenv.mkDerivation rec {
  name = "github-metadata-mirror";
  version = "fdab3206447dcb21d5854d7e64697afd80bd96d9";
  
  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "github-metadata-mirror";
    rev = version;
    sha256 = "sha256-z3wVa9bQvsn2KhCNWswZVd54etTwvJXj1Ny3KoDaHz4=";
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
