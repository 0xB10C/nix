{ stdenv, pkgs, lib, fetchFromGitHub, ... }:

pkgs.rustPlatform.buildRustPackage rec {
  name = "miningpool-observer";
  pname = "miningpool-observer";
  version = "bfe57d137c1b74777fefac44c2f527b4009242f2";

  src = fetchFromGitHub {
    owner = "0xB10C";
    repo = "miningpool-observer";
    rev = version;
    sha256 = "sha256-Iq1dyevGoB3JZcCTH+59DlkYdiPI45R55wP17YZZOOI=";
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
