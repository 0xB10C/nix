{ stdenv, pkgs, lib, rustPlatform, ... }:

let
  version = "a0c114abe6937cdcb88a396cec632d0c14560dbe";
  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "mainnet-observer";
    rev = version;
    sha256 = "sha256-cuwdpy+AYgJSepHmJb+1jpJrSLBZt19IjvQdKGXSRp4=";
  };
in {
  backend = rustPlatform.buildRustPackage rec {
    pname = "mainnet-observer";
    name = "mainnet-observer";

    inherit version src;

    sourceRoot = "source/backend";

    buildInputs = with pkgs; [ sqlite ];

    # during the integration tests, don't try to download a bitcoind binary
    # use the nix one instead
    BITCOIND_SKIP_DOWNLOAD = "1";
    BITCOIND_EXE = "${pkgs.bitcoind}/bin/bitcoind";

    cargoHash = "sha256-147O+H8Vc6BD1N9V6PNceOnJVBcKU96nM96DWkS3pKE=";

    meta = {
      description = "backend of mainnet-observer";
      homepage = "https://github.com/0xb10c/mainnet-observer";
      license = lib.licenses.mit;
    };
  };

  frontend = { title, baseURL, htmlTopRight, htmlBottomRight }:
    stdenv.mkDerivation {
      name = "mainnet-observer-frontend";

      inherit version src;

      sourceRoot = "source/frontend";

      buildPhase = ''
        export HUGO_TITLE="${title}"
        export HUGO_BASEURL="${baseURL}"
        export HUGO_PARAMS_HTMLTOPRIGHT="${htmlTopRight}"
        export HUGO_PARAMS_HTMLBOTTOMRIGHT="${htmlBottomRight}"
        ${pkgs.hugo}/bin/hugo --buildFuture --buildExpired --minify --logLevel=debug --printMemoryUsage --printPathWarnings --printUnusedTemplates
      '';

      installPhase = ''
        mkdir -p $out
        cp -r public/* $out/
      '';

      meta = {
        description = "frontend of mainnet-observer";
        homepage = "https://github.com/0xb10c/mainnet-observer";
        license = lib.licenses.mit;
      };
    };
}
