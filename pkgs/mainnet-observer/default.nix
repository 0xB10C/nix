{ stdenv, pkgs, lib, rustPlatform, ... }:

let
  version = "197e411dd401733f324d21d98e38e5716babb0d6";
  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "mainnet-observer";
    rev = version;
    sha256 = "sha256-XcCZqpRWgj0pS+PI5UX0oFuWg4Aw2zu2KgaYULBhXFk=";
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

    cargoHash = "sha256-wiamT85Cn5/I6I3817w7dbAW6Ad6Y+HnjLd+C070QqI=";

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
