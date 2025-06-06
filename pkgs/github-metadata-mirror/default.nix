{ stdenv, pkgs, lib, fetchFromGitHub, ... }:

stdenv.mkDerivation rec {
  name = "github-metadata-mirror";
  version = "d392dc0792686c1b022f7697f54e8b94440cc62d";
  
  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "github-metadata-mirror";
    rev = version;
    sha256 = "sha256-jYQpn1IKWF0fdMNtPoI2oCQYK9nKiWY21k992xKcafo=";
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
