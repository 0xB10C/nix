{ stdenv, pkgs, lib, fetchFromGitHub, ... }:

stdenv.mkDerivation rec {
  name = "asmap-data";
  version = "fcee1da1a4d94b32ffbbb0c8e34ce917d6b88b9b";
  
  src = pkgs.fetchFromGitHub {
    owner = "asmap";
    repo = "asmap-data"; # this is a demo repository. Update the description below when switching to another repo.
    rev = version;
    sha256 = "sha256-jsmz3IcIYQF+QRQ/Am1Pi3wANxltD3lrwvC3OlmRtUI=";
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
