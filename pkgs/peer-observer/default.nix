{ stdenv, pkgs, rustPlatform, ... }:

rustPlatform.buildRustPackage rec {
  name = "peer-observer";
  pname = "peer-observer";
  version = "d9b0ff3174d9c2936b3c938daee7e94d367d0281";

  src = pkgs.fetchFromGitHub {
    owner = "peer-observer";
    repo = "peer-observer";
    rev = version;
    sha256 = "sha256-95CkkoVd6dT5vsRRhRVfrZvluOKf13v4tYZNXpAxqOg=";
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

  cargoHash = "sha256-Cwah0BxB3DPMThupyVv9SdAAeY413bxKORF/WJrUCak=";

  meta = with stdenv.lib; {
    description = "Hooks into Bitcoin Core to observe how our peers interact with us.";
  };

  postInstall = ''
    cp -r $src/tools/metrics/dashboards $out
    cp -r $src/tools/websocket/www $out/websocket-www
  '';
}
