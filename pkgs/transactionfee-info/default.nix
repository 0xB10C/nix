{
  stdenv,
  pkgs,
  lib,
  rustPlatform,
  ...
}:

let
  version = "94b4b5c97f41757a10d546abe1dc6b66136ba427";
  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "transactionfee-info";
    rev = version;
    sha256 = "sha256-F2akxR9HP7Chdtr2CRPyU8sqLSZXSxwKzg0zhL6u0tE=";
  };
in
{
  backend = rustPlatform.buildRustPackage rec {
    pname = "transactionfee-info";
    name = "transactionfee-info";

    inherit version src;

    sourceRoot = "source/backend";

    buildInputs = with pkgs; [ sqlite ];

    # during the integration tests, don't try to download a bitcoind binary
    # use the nix one instead
    BITCOIND_SKIP_DOWNLOAD = "1";
    BITCOIND_EXE = "${pkgs.bitcoind}/bin/bitcoind";

    cargoHash = "sha256-1FKxYKUb6sKBnCa5U6N/JjNTthYhiEhyPOq3De6t/C4=";

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
