{ stdenv, pkgs, rustPlatform, ... }:

rustPlatform.buildRustPackage rec {
  name = "peer-observer";
  version = "b0b6c461121a211e2ee48d08cb88653a0cc02f5c";

  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "peer-observer";
    rev = version;
    sha256 = "sha256-77h7p2NnF1SIXQjuvwVyJY0ofqvEYNFxFp2a33ErWLM=";
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

  cargoHash = "sha256-7o+BK2KAGWDFo+A78SqoYSyyDBDy/1iKDfVDysDUNgA=";

  meta = with stdenv.lib; {
    description = "Hooks into Bitcoin Core to observe how our peers interact with us.";
  };

  postInstall = ''
    cp -r $src/tools/metrics/dashboards $out
    cp -r $src/tools/websocket/www $out/websocket-www
  '';
}
