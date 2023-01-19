{ stdenv, pkgs, lib, fetchFromGitHub, ... }:

pkgs.rustPlatform.buildRustPackage rec {
  name = "miningpool-observer";

  src = fetchFromGitHub {
    owner = "0xB10C";
    repo = "miningpool-observer";
    rev = "026799372ae9a1d603e59ab1b71623ed22a66cbc";
    sha256 = "sha256-d+uFWIplWJZ9BANOHfHX0ma/z+lhkvUEfTf4jWbyYFE=";
  };

  buildInputs = [ pkgs.postgresql ];

  cargoSha256 = "sha256-X0DM+XDmTNWvwqQN4UMyiPDFGzEZXMWzPPhmz+WeVCI=";

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
