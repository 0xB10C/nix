{ stdenv, pkgs, rustPlatform, ... }:

rustPlatform.buildRustPackage rec {
  name = "peer-observer";

  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "peer-observer";
    rev = "33540426ec77d58be749f15c9e02f158b3fb7bbe";
    sha256 = "sha256-x5eB/dqcrBWODQ/IkoBOMwnrmLFhb4TKEJvnaBvfqgY=";
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

  cargoSha256 = "sha256-m5iPvO3YXVY/TIrRaFdCSapVhThcy3aD+nOrlKgmK4k=";

  meta = with stdenv.lib; {
    description = "Hooks into Bitcoin Core to observe how our peers interact with us.";
  };

  postInstall = ''
    mkdir $out/dashboards
    cp -r $src/metrics/dashboards/* $out/dashboards

    mkdir $out/tools
    mkdir $out/tools/addrman-observer
    cp -r $src/tools/addrman-observer/index.html $out/tools/addrman-observer/index.html
  '';
}
