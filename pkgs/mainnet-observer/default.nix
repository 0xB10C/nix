{ stdenv, pkgs, lib, rustPlatform, ... }:

let
  version = "8573a33a801a0597e28f4e2722426edd6f54ff4c";
  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "mainnet-observer";
    rev = version;
    sha256 = "sha256-DeBwtGj5kz8VyhCC47+hZryYR7ONfIgChW0Rrv+kHe0=";
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

    cargoHash = "sha256-7GIUv0BDN+be5OKuFykBMT4962LwOGos0+JdPZzc2BE=";

    meta = {
      description = "backend of mainnet-observer";
      homepage = "https://github.com/0xb10c/mainnet-observer";
      license = lib.licenses.mit;
    };
  };

  frontend = { title, baseURL, htmlTopRight, htmlBottomRight }:
    stdenv.mkDerivation {
      name = "mainnet-observer-frontend";
      pname = "mainnet-observer-frontend";

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
