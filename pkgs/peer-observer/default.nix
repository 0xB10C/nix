{ stdenv, pkgs, rustPlatform, ... }:

rustPlatform.buildRustPackage rec {
  name = "peer-observer";
  version = "76b1b583b0620834f856a0ce136d2924231d1820";

  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "peer-observer";
    rev = version;
    sha256 = "sha256-RLUjpqQ0jvXX/XFkBviWC/4aN6xnQOPnPuiUN21K3uw=";
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
    pkgs.llvmPackages_20.clang-unwrapped
    pkgs.pkg-config

    # needed for libbpf-cargo
    pkgs.rustfmt
  ];

  # during the integration tests, don't try to download a bitcoind binary
  # use the nix one instead
  BITCOIND_SKIP_DOWNLOAD = "1";
  BITCOIND_EXE = "${pkgs.bitcoind}/bin/bitcoind";
  # Overwrite the default `cargo check` with `cargo test --all-features`
  # to run the integration tests.
  checkPhase = ''
    export NATS_SERVER_BINARY="${pkgs.nats-server}/bin/nats-server"
    cargo test --all-features
  '';

  # set the path of the Linux kernel headers. These are needed in
  # build.rs of the ebpf-extractor on Nix.
  KERNEL_HEADERS = "${pkgs.linuxHeaders}/include";

  cargoHash = "sha256-lpvLruvXXZNswHjtSUV/xRHst2QUlaPOh13Hsgc7qxc=";

  meta = with stdenv.lib; {
    description = "Hooks into Bitcoin Core to observe how our peers interact with us.";
  };

  postInstall = ''
    cp -r $src/tools/metrics/dashboards $out
    cp -r $src/tools/websocket/www $out/websocket-www
  '';
}
