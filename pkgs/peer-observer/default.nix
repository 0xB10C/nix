{ stdenv, pkgs, rustPlatform, ... }:

rustPlatform.buildRustPackage rec {
  name = "peer-observer";

  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "peer-observer";
    rev = "722ac062f549d7ee8ac48d05720b9d6ffa97baa5";
    sha256 = "sha256-qZK2IlPDkedYfOIwLCnnV53GnbXOtsCHO5DOSLJ+04A=";
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

  cargoHash = "sha256-4ONh2ivZv9cIfLZZOsm/iOShsLJqbb9GQW3lRDQGFAU=";

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "libbpf-cargo-0.22.0" = "sha256-TdC2PrmIZQuauyIHEPgepi707GIwLFvSqIET82flUb0=";
      "libbpf-sys-1.0.3+v1.0.1" = "sha256-PStZhxdHVdtVPu+b9Mc8jsXyHZE0+/y/c0/Ac8mY0Hk="; 
    };
  };

  meta = with stdenv.lib; {
    description = "Hooks into Bitcoin Core to observe how our peers interact with us.";
  };

  postInstall = ''
    cp -r $src/tools/metrics/dashboards $out
  '';
}
