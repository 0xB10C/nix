{ stdenv, pkgs, lib, rustPlatform, ... }:

rustPlatform.buildRustPackage rec {
  pname = "fork-observer";
  name = "fork-observer";
  version = "f300fd7448ab06a46969ed4dcb90e9fed535d0b4";

  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "fork-observer";
    rev = version;
    sha256 = "sha256-bsXej75dbtOfh9Ic7S/uySd9LAZxWpwg/kdyJDHsnio=";
  };

  nativeBuildInputs = with pkgs; [ sqlite ];

  cargoHash = "sha256-y2fwyFkYZxvHN3KA3vBw31eP/j2z3n+Bs+1vJJJnGw0=";

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
