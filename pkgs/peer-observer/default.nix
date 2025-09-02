{ stdenv, pkgs, rustPlatform, ... }:

rustPlatform.buildRustPackage rec {
  name = "peer-observer";
  version = "fac62164d0908c3e48311780529c501510564cd7";

  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "peer-observer";
    rev = version;
    sha256 = "sha256-aogblcOY4Vg5bSNgzMTgzAFvlGuHF3FEfH9RqMRq5+8=";
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

  cargoHash = "sha256-cw+CX2QrjTArDo5AmJiPs1u9ZydZqd0QxZifMgR2qqc=";

  meta = with stdenv.lib; {
    description = "Hooks into Bitcoin Core to observe how our peers interact with us.";
  };

  postInstall = ''
    cp -r $src/tools/metrics/dashboards $out
    cp -r $src/tools/websocket/www $out/websocket-www
  '';
}
