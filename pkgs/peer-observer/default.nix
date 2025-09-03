{ stdenv, pkgs, rustPlatform, ... }:

rustPlatform.buildRustPackage rec {
  name = "peer-observer";
  version = "7f67949f2227b166a31c38ca3fd0f2d0358a5596";

  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "peer-observer";
    rev = version;
    sha256 = "sha256-rETWndmZnH1yC9SQEOEY3RYB5kBWUKqS44jw/ZOsLL4=";
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

  cargoHash = "sha256-2JlWvschAC3H8DP4ljFsrPQnTbT7YJKrfBaGJWO6O7k=";

  meta = with stdenv.lib; {
    description = "Hooks into Bitcoin Core to observe how our peers interact with us.";
  };

  postInstall = ''
    cp -r $src/tools/metrics/dashboards $out
    cp -r $src/tools/websocket/www $out/websocket-www
  '';
}
