{
  stdenv,
  pkgs,
  lib,
  rustPlatform,
  ...
}:

let
  version = "a5d030e136749e7d7c0ae14924fb7958471be820";
  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "transactionfee-info";
    rev = version;
    sha256 = "sha256-C7v8Mq6ML4d+jEd7Qz8xf5DBeqLbRTGD4md7gLnA+uk=";
  };
in
{
  backend = rustPlatform.buildRustPackage rec {
    pname = "transactionfee-info";
    name = "transactionfee-info";

    inherit version src;

    sourceRoot = "source/backend";

    buildInputs = with pkgs; [ sqlite ];

    cargoHash = "sha256-+CcD/PzKI4NsOpww5t0xB7ej1wDSmda1WARXVptVRus=";

    meta = {
      description = "backend of transactionfee-info";
      homepage = "https://github.com/0xb10c/transactionfee-info";
      license = lib.licenses.mit;
    };
  };

  frontend = stdenv.mkDerivation {
    name = "transactionfee-info-frontend";

    inherit version src;

    sourceRoot = "source/frontend";

    buildPhase = ''
      ${pkgs.hugo}/bin/hugo --buildFuture --buildExpired --minify --logLevel=debug --printMemoryUsage --printPathWarnings --printUnusedTemplates
    '';

    installPhase = ''
      mkdir -p $out
      cp -r public/* $out/
    '';

    meta = {
      description = "frontend of transactionfee-info";
      homepage = "https://github.com/0xb10c/transactionfee-info";
      license = lib.licenses.mit;
    };
  }; 
}
