{ stdenv, pkgs, lib, rustPlatform, ... }:

rustPlatform.buildRustPackage rec {
  pname = "fork-observer";
  name = "fork-observer";
  version = "46dbfc1348c15f4ed7fc8ea0a78fd65443e48e80";

  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "fork-observer";
    rev = version;
    sha256 = "sha256-kkvPDKrTdE+Q4aND9mON2RdPnkJFKaCa6u4NQZLXCAU=";
  };

  nativeBuildInputs = with pkgs; [ sqlite ];

  cargoHash = "sha256-CostORLvRVZ3bflIU9SskQvy7I4rqCc4G+GC4AVZGe4=";

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
