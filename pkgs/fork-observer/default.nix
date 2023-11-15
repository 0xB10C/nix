{ stdenv, pkgs, lib, rustPlatform, ... }:

rustPlatform.buildRustPackage rec {
  pname = "fork-observer";
  name = "fork-observer";

  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "fork-observer";
    rev = "bb39577ee38156faf79f43c9a310ebfd8e662e14";
    sha256 = "sha256-/u2g4MB4Uw4QDNncqUz/ierX/fY1b159cXBW0NBWQHE=";
  };

  nativeBuildInputs = with pkgs; [ sqlite ];

  cargoSha256 = "sha256-TOIEdqgWmdy947Ox0UmAbrEM27xddGVLbmZuaHE6Njo=";

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
