{ stdenv, pkgs, lib, fetchFromGitHub, ... }:

stdenv.mkDerivation rec {
  name = "asmap-data";
  version = "3e572e767c2702de4583c74d89de206ca592d113";
  
  src = pkgs.fetchFromGitHub {
    owner = "asmap";
    repo = "asmap-data"; # this is a demo repository. Update the description below when switching to another repo.
    rev = version;
    sha256 = "sha256-paNrWZVEX/Cqc6BgGRemnEfuQu1BUDNW3Z7C1FPshQQ=";
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
