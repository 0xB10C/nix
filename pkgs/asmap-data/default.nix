{ stdenv, pkgs, lib, fetchFromGitHub, ... }:

stdenv.mkDerivation rec {
  name = "asmap-data";
  version = "d65f37e8e0a31cbd5348213c861d5c48c72e7402";
  
  src = pkgs.fetchFromGitHub {
    owner = "asmap";
    repo = "asmap-data"; # this is a demo repository. Update the description below when switching to another repo.
    rev = version;
    sha256 = "sha256-q9Ws05ksL885PM03tRzm0uENDSOnQ9a8F2Mm6kqwLd4=";
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
