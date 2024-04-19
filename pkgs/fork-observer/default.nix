{ stdenv, pkgs, lib, rustPlatform, ... }:

rustPlatform.buildRustPackage rec {
  pname = "fork-observer";
  name = "fork-observer";

  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "fork-observer";
    rev = "6b6ce36c7cbddc49793d240df6ca51f7e27f4bc7";
    sha256 = "sha256-qK2csmL7uTGAOLEVOnLZ2CRSB0y6EW9HRukQKmJQ/5c=";
  };

  nativeBuildInputs = with pkgs; [ sqlite ];

  cargoSha256 = "sha256-/Dy2Hh7aNfWAC7YngNKawzEz819WMue8xqcmDRDSa4I=";

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
