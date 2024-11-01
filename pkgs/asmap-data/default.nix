{ stdenv, pkgs, lib, fetchFromGitHub, ... }:

stdenv.mkDerivation rec {
  name = "asmap-data";
  version = "71b95ddab9640d1637c422a04730c352d210f741";
  
  src = pkgs.fetchFromGitHub {
    owner = "asmap";
    repo = "asmap-data"; # this is a demo repository. Update the description below when switching to another repo.
    rev = version;
    sha256 = "sha256-N2LldOWTbOf3evY+8U6+EciZWW6A33XTMH2UgMKJ3/0=";
  };

  installPhase = ''
    cp -r $src/latest_asmap.dat $out
  '';

  meta = {
    description = "Contains an asmap file from the ASMap Data Demo Repository";
    homepage = "https://github.com/asmap/asmap-data";
    license = lib.licenses.mit;
  };
}
