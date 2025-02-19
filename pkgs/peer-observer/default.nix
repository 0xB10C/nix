{ stdenv, pkgs, rustPlatform, ... }:

rustPlatform.buildRustPackage rec {
  name = "peer-observer";
  version = "32ae4acdfca0a174ab5a05840a99fed2aec77e8c";
  
  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "peer-observer";
    rev = version;
    sha256 = "sha256-euFR9pOZdsE+qH13Zaywjsc1VaAwlODZodgQ2MsocM8=";
  };

  hardeningDisable = [
    "stackprotector"
    "fortify"
  ];

  buildInputs = [
    # for building libbpf
    pkgs.elfutils
    pkgs.zlib
  ];

  nativeBuildInputs = [
    pkgs.protobuf
    pkgs.cmake

    # for building libbpf
    pkgs.clang_14
    pkgs.pkg-config

    # needed for libbpf-cargo
    pkgs.rustfmt
  ];

  cargoHash = "sha256-VRCTCbLd0gWNBbwVOSZnXDlTsVJarM6VUbbnASLpKms=";

  meta = with stdenv.lib; {
    description = "Hooks into Bitcoin Core to observe how our peers interact with us.";
  };

  postInstall = ''
    cp -r $src/tools/metrics/dashboards $out
    cp -r $src/tools/websocket/www $out/websocket-www
  '';
}
