{
  stdenv,
  pkgs,
  lib,
  rustPlatform,
  ...
}:

let
  version = "1588d86a76ab1e2c3f06c10b29b5878490cae995";
  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "transactionfee-info";
    rev = version;
    sha256 = "sha256-jzZIn1NCAucQlRLBrc/GToM95f15INr/kX4wrxyagOg=";
  };
in
{
  backend = rustPlatform.buildRustPackage rec {
    pname = "transactionfee-info";
    name = "transactionfee-info";

    inherit version src;

    sourceRoot = "source/backend";

    buildInputs = with pkgs; [ sqlite bitcoind ];

    # during the integration tests, don't try to download a bitcoind binary
    # use the nix one instead
    BITCOIND_SKIP_DOWNLOAD = 1;
    BITCOIND_EXE="${pkgs.bitcoind}/bin/bitcoind";

    cargoLock = {
      lockFile = ./Cargo.lock;
      outputHashes = {
        "rawtx-rs-0.1.14" = "sha256-OppVX6VdmlhoFqPaZjsT2+0cTWeghaXaPXQ28cn9n0k=";
      };
    };


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
