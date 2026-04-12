{ lib, stdenv, python3, fetchFromGitHub, makeWrapper, ... }:

let
  python = python3.withPackages (ps: [ ps.mistune ]);
in

stdenv.mkDerivation rec {
  pname = "github-metadata-mirror";
  version = "1a7c049d2498551e4858a59b2c76dce1b4c70d0d";

  src = fetchFromGitHub {
    owner = "0xB10C";
    repo = "github-metadata-mirror";
    rev = version;
    sha256 = "sha256-ex1a9EFJ7N4thr5QVnHH5kEBom84O5TR0Lep0CR1RxU=";
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
