{ stdenv, pkgs, lib, fetchFromGitHub, ... }:

pkgs.rustPlatform.buildRustPackage rec {
  name = "miningpool-observer";
  version = "5be547200d02bc4f010b1d68c805b444a741251d";

  src = fetchFromGitHub {
    owner = "0xB10C";
    repo = "miningpool-observer";
    rev = version;
    sha256 = "sha256-TIa8HdMCXREDcTIlQy87StqQUPxOqUWvhzhwhKMq94g=";
  };

  buildInputs = [ pkgs.postgresql ];

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "bitcoincore-rpc-0.19.0" = "sha256-ZMRJ1pMzy9wcE9zWmSER+ekFKqockGWqhvDIOTB6tgI=";
    };
  };

  cargoHash = "";

  postInstall = ''
    cp -r www $out/www
  '';

  meta = {
    description = "Transparency for Mining Pool Transaction Selection";
    longDescription = ''
      The miningpool-observer project compares block templates produced by a
      Bitcoin Core node to blocks produced by mining pools to provide insights
      about:
      - Shared, missing, and extra transactions per template and block pair
      - Transactions missing from multiple blocks they should have been included in
      - Template and block transactions conflicting with each other
      - Blocks not including transactions to or from OFAC sanctioned addresses
    '';
    homepage = "https://github.com/0xb10c/miningpool-observer";
    license = lib.licenses.mit;
  };
}
