{ stdenv, pkgs, lib, rustPlatform, ... }:

rustPlatform.buildRustPackage rec {
  pname = "fork-observer";
  name = "fork-observer";
  version = "cf4d2c3bfc78e22c284aa3bd2fe6c1a833ea23aa";

  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "fork-observer";
    rev = version;
    sha256 = "sha256-qm9I9Mre9vESZbRxk27oKYgV0RQVZPK68wxvdR3wAZU=";
  };

  nativeBuildInputs = with pkgs; [ sqlite ];

  cargoHash = "sha256-JGgdNYmxgvoFARQ8N82wRf6cbZwhWy63HwZWP97tqd0=";

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
