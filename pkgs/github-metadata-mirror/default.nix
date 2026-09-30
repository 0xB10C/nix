{ lib, stdenv, python3, fetchFromGitHub, makeWrapper, ... }:

let
  python = python3.withPackages (ps: [ ps.mistune ]);
in

stdenv.mkDerivation rec {
  pname = "github-metadata-mirror";
  version = "47afc6e040054cec042397299548cd5f08188e44";

  src = fetchFromGitHub {
    owner = "0xB10C";
    repo = "github-metadata-mirror";
    rev = version;
    sha256 = "sha256-0PCjot3W1zC22o+hVLICszTlFBup4vXAwhnPQi5IAho=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/share/github-metadata-mirror $out/bin
    cp -r build.py mirror static $out/share/github-metadata-mirror/

    makeWrapper ${python}/bin/python $out/bin/github-metadata-mirror \
      --add-flags "$out/share/github-metadata-mirror/build.py"
  '';

  meta = {
    description = "A GitHub metadata mirror";
    longDescription = ''
      Generates a static HTML GitHub metadata mirror for archiving GitHub
      comments and reviews on issues and pull requests. Reads JSON backup
      files from github-metadata-backup and produces a self-contained
      static site.
    '';
    homepage = "https://github.com/0xb10c/github-metadata-mirror";
    license = lib.licenses.mit;
  };
}
