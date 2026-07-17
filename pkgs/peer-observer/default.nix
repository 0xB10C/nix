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
  version = "5c0a53f5581c094f6319bef4f0347b9905a7a08f";

  src = pkgs.fetchFromGitHub {
    owner = "peer-observer";
    repo = "peer-observer";
    rev = version;
    sha256 = "sha256-9wUJsfw4FFur/LK9fIqZZk+kK5HPdm51VTyItaELR6A=";
  };

  # needed for the archiver to know the GIT_HASH
  GIT_HASH = version;

  hardeningDisable = [
    "stackprotector"
    "fortify"
  ];

  buildInputs = with pkgs; [
    zlib
  ] ++ lib.optionals enableTracing [
    elfutils
  ];

  nativeBuildInputs = with pkgs; [
    protobuf
    cmake
    git
    capnproto
  ] ++ lib.optionals enableTracing [
    llvmPackages_20.clang-unwrapped
    pkg-config
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

  cargoHash = "sha256-uyBgS7emGcTojq17dU1AlZLHDn1YrXSAwpUKQIvBM0Q=";

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
