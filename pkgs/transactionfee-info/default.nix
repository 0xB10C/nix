{
  stdenv,
  pkgs,
  lib,
  rustPlatform,
  ...
}:

let
  version = "8822ac6b09bae72f190f849f13c3d9c2e5237856";
  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "transactionfee-info";
    rev = version;
    sha256 = "sha256-XFcWmi4NiebIfG3A7yX9HRTvmcsYZhoEJXmiabHBDMA=";
  };
in
{
  backend = rustPlatform.buildRustPackage rec {
    pname = "transactionfee-info";
    name = "transactionfee-info";

    inherit version src;

    sourceRoot = "source/backend";

    buildInputs = with pkgs; [ sqlite ];

    cargoHash = "sha256-ss0gdiOsvFnVqt96LuTA/nqBLXIHLaCH7ZVmikaAV2U=";

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
