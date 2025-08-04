{ stdenv, pkgs, lib, rustPlatform, ... }:

rustPlatform.buildRustPackage rec {
  pname = "fork-observer";
  name = "fork-observer";
  version = "8c4005310dce737e9abf13ed9b33751d30fdef6c";

  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "fork-observer";
    rev = version;
    sha256 = "sha256-NnmI9x6Hhx+5Roj6i5Milc3IdPkFwt25EzCtq3X0dMI=";
  };

  nativeBuildInputs = with pkgs; [ sqlite ];

  cargoHash = "sha256-Uki55GUHsnBk3T8dsUULyV6l/X3LR0eCZavbRI/JAbg=";

  postInstall = ''
    cp -r www $out/www
  '';

  meta = with stdenv.lib; {
    description = "Tool for monitoring forks and reorgs on Bitcoin networks.";
    longDescription = ''
      The fork-observer can be hooked up to one or more Bitcoin Core nodes via
      the RPC interface. It gathers and visualizes data on block headers, forks
      in the chain, and stale blocks. It supports multiple networks (mainnet,
      testnet, (custom) signets, ...).
    '';
    homepage = "https://github.com/0xb10c/fork-observer";
    license = lib.licenses.mit;
  };
}
