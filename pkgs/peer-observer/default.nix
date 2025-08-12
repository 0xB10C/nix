{ stdenv, pkgs, rustPlatform, ... }:

rustPlatform.buildRustPackage rec {
  name = "peer-observer";
  version = "a53e617f23e26c3e0248e458530bbfa8a078328b";

  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "peer-observer";
    rev = version;
    sha256 = "sha256-v0A5zDYHdoUVlf78GMHLnxgtpKUNOlDfEUjrFAbvSTk=";
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

  cargoHash = "sha256-FMzHFPutO7Bz6J4sW8r97rVtv5urmm6sNHqjRSE/DQE=";

  meta = with stdenv.lib; {
    description = "Hooks into Bitcoin Core to observe how our peers interact with us.";
  };

  postInstall = ''
    cp -r $src/tools/metrics/dashboards $out
    cp -r $src/tools/websocket/www $out/websocket-www
  '';
}
