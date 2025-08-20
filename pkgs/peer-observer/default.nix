{ stdenv, pkgs, rustPlatform, ... }:

rustPlatform.buildRustPackage rec {
  name = "peer-observer";
  version = "06b034aab3d01b4156350e862f39c12fd8291111";

  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "peer-observer";
    rev = version;
    sha256 = "sha256-T9LQRb21xDgHG2uPC9V4SURlUV9Jp0/WmB7fhNw3voY=";
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
