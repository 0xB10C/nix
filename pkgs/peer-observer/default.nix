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
  version = "d3f7a519d36711092d752fc27b9a965e23db4428";

  src = pkgs.fetchFromGitHub {
    owner = "peer-observer";
    repo = "peer-observer";
    rev = version;
    sha256 = "sha256-hF/7dbP3ssjSGbihff8+kKEpcrD6fciRa42pBenp7bM=";
  };

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

  cargoHash = "sha256-toBHuDMjWVaaX+VJ1mXuAvRxUBg95ciEYjJgHryJD9I=";

  # Set the path of the Linux kernel headers for the ebpf-extractor.
  KERNEL_HEADERS = lib.derivations.optionalDrvAttr enableTracing 
    "${pkgs.linuxHeaders}/include";

  # In the integration tests, use the nix bitcoind and nats binaries.
  BITCOIND_SKIP_DOWNLOAD = "1";
  BITCOIND_EXE = "${pkgs.bitcoind}/bin/bitcoind";
  NATS_SERVER_BINARY="${pkgs.nats-server}/bin/nats-server";

  meta = {
    description = "Hooks into Bitcoin Core to observe how our peers interact with us.";
  };

  postInstall = ''
    cp -r $src/tools/metrics/dashboards $out
    cp -r $src/tools/websocket/www $out/websocket-www
  '';
}
