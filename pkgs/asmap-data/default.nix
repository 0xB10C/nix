{ stdenv, pkgs, lib, fetchFromGitHub, ... }:

stdenv.mkDerivation rec {
  name = "asmap-data";
  version = "4c6a7cde4f9abbabae8e3b6c56f9cb6c3670ea1d";
  
  src = pkgs.fetchFromGitHub {
    owner = "asmap";
    repo = "asmap-data"; # this is a demo repository. Update the description below when switching to another repo.
    rev = version;
    sha256 = "sha256-7iDIisT78N4qBI09u3e8lqr906Sr97q7AK6ezmCBx4U=";
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
