{ stdenv, pkgs, lib, rustPlatform, ... }:

rustPlatform.buildRustPackage rec {
  pname = "fork-observer";
  name = "fork-observer";

  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "fork-observer";
    rev = "03194dc5064609d4d402e7bde8f0055495185f31";
    sha256 = "sha256-ytZuHPD0gMgaUI9UOEkTGDp08lBR/SXk+kX6GMFis7I=";
  };

  nativeBuildInputs = with pkgs; [ sqlite ];

  cargoSha256 = "sha256-Mwx3kso0yS8kLZ9h6CX7sZKKLRQV0Qi1dF2LXKsvitY=";

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
