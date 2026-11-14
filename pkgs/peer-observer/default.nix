{ stdenv
, lib
, pkgs
, rustPlatform
, enableTracing ? stdenv.hostPlatform.isLinux && !stdenv.hostPlatform.isStatic
, ...
}:

rustPlatform.buildRustPackage rec {
  name = "peer-observer";
  pname = "peer-observer";
  version = "8889014d3ae01e3f14795041cb4ff501c5c61aa0";

  src = pkgs.fetchFromGitHub {
    owner = "peer-observer";
    repo = "peer-observer";
    rev = version;
    sha256 = "sha256-J0zH+qPiZpZillqaPA5IwsNA0F/ix15bklsHEaH+xwE=";
  };

  # needed for the archiver to know the GIT_HASH
  GIT_HASH = version;

  hardeningDisable = [
    "stackprotector"
    "fortify"
  ];

  buildInputs = with pkgs; [
    zlib
    zstd
  ] ++ lib.optionals enableTracing [
    elfutils
  ];

  nativeBuildInputs = with pkgs; [
    protobuf
    pkg-config
    cmake
    git
    capnproto
  ] ++ lib.optionals enableTracing [
    llvmPackages_20.clang-unwrapped
    rustfmt
  ];

  cargoBuildFlags = lib.optionals (!enableTracing) [
      "--workspace --exclude ebpf-extractor"
  ];

  cargoTestFlags = [
    "--all-features"
  ] ++ lib.optionals (!enableTracing) [
      "--workspace --exclude ebpf-extractor"
  ] ++ lib.optionals (pkgs.stdenv.hostPlatform.isDarwin) [
      "--exclude log-extractor"
  ];

  cargoHash = "sha256-GOswqe5rre4p0SB3f0JiOXz3886GMOsvylZwn/ed/EM=";

  # The libbpf vendored by libbpf-sys ships its own linux/types.h, which shadows
  # the kernel one and lacks __s128/__u128. Newer kernel headers use __u128 in
  # arm64's asm/sigcontext.h and asm/ptrace.h, breaking the build on aarch64.
  # Fixed in libbpf f90a9c487d ("include: add 128-bit integer types to
  # linux/types.h"), but not yet in a libbpf-sys release. The flags are passed
  # to make as CFLAGS (split on whitespace), so force-include a header instead
  # of using -D.
  LIBBPF_SYS_EXTRA_CFLAGS = lib.optionalString enableTracing "-include ${pkgs.writeText "libbpf-u128.h" ''
    #ifdef __SIZEOF_INT128__
    typedef __signed__ __int128 __s128 __attribute__((aligned(16)));
    typedef unsigned __int128 __u128 __attribute__((aligned(16)));
    #endif
  ''}";

  # Set the path of the Linux kernel headers for the ebpf-extractor.
  KERNEL_HEADERS = lib.derivations.optionalDrvAttr enableTracing
    "${pkgs.linuxHeaders}/include";

  # In the integration tests, use the nix bitcoind and nats binaries.
  BITCOIND_SKIP_DOWNLOAD = "1";
  BITCOIND_EXE = "${pkgs.bitcoind}/bin/bitcoind";
  BITCOIN_NODE_EXE = "${pkgs.bitcoind}/libexec/bitcoin-node";
  NATS_SERVER_BINARY="${pkgs.nats-server}/bin/nats-server";
  
  passthru = {
    # directory with the Grafana dashboards of the metrics tool
    metrics-dashboards = "${src}/tools/metrics/dashboards";
    # directory with the Prometheus rules of the metrics tool
    metrics-prometheus-rules = "${src}/tools/metrics/prometheus";
    # directory with the Websocket www pages
    websocket-www-pages = "${src}/tools/websocket/www";
  };

  meta = {
    description = "Hooks into Bitcoin Core to observe how our peers interact with us.";
  };
}
