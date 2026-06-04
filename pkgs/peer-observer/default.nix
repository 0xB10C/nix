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
  version = "8cf98b3ba3747ce176117f044f9759a6d8761ba7";

  src = pkgs.fetchFromGitHub {
    owner = "peer-observer";
    repo = "peer-observer";
    rev = version;
    sha256 = "sha256-V0Qf3MgsLOM38FO9DzTo3p3RgsUcwmyfygoHr8fFGdw=";
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

  cargoHash = "sha256-SnqCp2bvHO/GfDzDSuaKvW4zLU9JEEtnhua/i7xUH9M=";

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
