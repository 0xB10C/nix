{ stdenv, pkgs, lib, rustPlatform, ... }:

let
  version = "4059467a507586b68162a0819b328fe62c9febba";
  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "mainnet-observer";
    rev = version;
    sha256 = "sha256-YogzlqGJDLUAUTnsw0WVKqxmguFne3B/4ZI5f+Or358=";
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

    cargoHash = "sha256-0MqnejdXkY8IimQ1sT3J4EJLmdDLvboXkjXIQHrSi8Q=";

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
