{ stdenv, pkgs, lib, rustPlatform, ... }:

rustPlatform.buildRustPackage rec {
  pname = "fork-observer";
  name = "fork-observer";
  version = "264718066213283742323c588a2e154d6d134848";

  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "fork-observer";
    rev = version;
    sha256 = "sha256-BTA2a6KKMWTIv/ewTrnFzdvY0lFg0+DkFuGCBVoony8=";
  };

  nativeBuildInputs = with pkgs; [ sqlite ];

  cargoHash = "sha256-HDab8NnBDTpuvy/r0fndUy02Oicuo18YthDJet2kazI=";

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
