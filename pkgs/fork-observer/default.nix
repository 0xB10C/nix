{ stdenv, pkgs, lib, rustPlatform, ... }:

rustPlatform.buildRustPackage rec {
  pname = "fork-observer";
  name = "fork-observer";
  version = "537716060257ebb25ea81abda937109e157a1802";

  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "fork-observer";
    rev = version;
    sha256 = "sha256-X/DThqdD747vmxDZ5+fmZdjIIXghbUv6FUOY57kRGjo=";
  };

  nativeBuildInputs = with pkgs; [ sqlite ];

  cargoHash = "sha256-ekNiSPv2rdKssMBQKLiCqxfoJmMiXJrc4EgVSbXy8nA=";

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
