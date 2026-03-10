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
  version = "c786df7649b04c101a3d59c1dfeaed82495d1c31";

  src = pkgs.fetchFromGitHub {
    owner = "peer-observer";
    repo = "peer-observer";
    rev = version;
    sha256 = "sha256-KneE/rKUXhS9DFIEgzwhXbGdEIrn/tJD8Qh+WsDZIvw=";
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

  cargoHash = "sha256-CNbNliqp4BwbdySoD+BFfq9QsIYDiaKRZdD/oBgwyvo=";

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
