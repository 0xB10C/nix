{ stdenv
, lib
, fetchFromGitHub
, rustPlatform
, runCommand
, clang
, pkg-config
, bpftools
, linuxHeaders
, elfutils
, zlib
, zstd
}:

let
  rev = "9afa9ee5493814c7791586f2179aa93528fde54a";

  src = fetchFromGitHub {
    owner = "anakryiko";
    repo = "wprof";
    inherit rev;
    hash = "sha256-jo9j0T3ZDz6CCq/Waxxb4Aa5lKcuslg5SympgSeNuUM=";
    fetchSubmodules = true;
  };

  # Pre-built so cargo doesn't run in the main sandbox.
  libblazesym-c = rustPlatform.buildRustPackage {
    pname = "blazesym-c";
    version = "0-unstable-2025-05-20";

    src = fetchFromGitHub {
      owner = "libbpf";
      repo = "blazesym";
      rev = "b5c3e60c8a441266ea1878be20d7b2e98f7c01f7";
      hash = "sha256-zAFEnNH0Hk3SXpURDrE2C0I5e8haD+JgROGHGSLNoL0=";
    };

    cargoBuildFlags = [ "--package=blazesym-c" ];
    cargoHash = "sha256-nC6xhW8G+7GHW63hJutW3ZM73GPjR9Sw6wZcK20ka+Y=";
    doCheck = false;

    installPhase = ''
      runHook preInstall
      install -Dm644 target/*/release/libblazesym_c.a $out/lib/libblazesym_c.a
      mkdir -p $out/include
      cp -r capi/include/. $out/include/
      runHook postInstall
    '';
  };

  # Pre-built so cargo doesn't run in the main sandbox.
  libdemangle-c = rustPlatform.buildRustPackage {
    pname = "demangle-c";
    version = "0.1.0";

    src = runCommand "demangle-c-source" { } ''
      mkdir -p $out
      cp -r ${src}/src/demangle/. $out/
    '';

    cargoLock.lockFile = ./demangle-Cargo.lock;
    doCheck = false;

    installPhase = ''
      runHook preInstall
      install -Dm644 target/*/release/libdemangle_c.a $out/lib/libdemangle_c.a
      runHook postInstall
    '';
  };

in

stdenv.mkDerivation {
  pname = "wprof";
  version = "0.4-unstable-2026-05-28";
  inherit src;

  nativeBuildInputs = [ clang pkg-config ];

  buildInputs = [ elfutils zlib zstd ];

  # clang.cc (unwrapped) avoids NIX hardening flags invalid for --target bpf.
  # CLANG_BPF_SYS_INCLUDES is set explicitly because the unwrapped binary has
  # no NIX-injected system paths; we add glibc dev and kernel UAPI headers.
  preBuild = ''
    clangBuiltins=$(${clang.cc}/bin/clang -v -E - </dev/null 2>&1 | \
      sed -n '/<...> search starts here:/,/End of search list./{ s| \(/.*\)|-idirafter \1|p }')
    export CLANG_BPF_SYS_INCLUDES="$clangBuiltins -idirafter ${stdenv.cc.libc.dev}/include -idirafter ${linuxHeaders}/include"
  '';

  # make runs from src/ so relative submodule paths (../libbpf, etc.) resolve
  # correctly. Rust libs are pre-built; cargo never runs here.
  makeFlags = [
    "-C" "src"
    "CLANG=${clang.cc}/bin/clang"
    "BPFTOOL=${bpftools}/bin/bpftool"
    "LIBBLAZESYM_OBJ=${libblazesym-c}/lib/libblazesym_c.a"
    "LIBBLAZESYM_INC=${libblazesym-c}/include"
    "LIBDEMANGLE_OBJ=${libdemangle-c}/lib/libdemangle_c.a"
  ];

  installFlags = [
    "DESTDIR=${placeholder "out"}"
    "prefix="
  ];

  enableParallelBuilding = true;

  meta = with lib; {
    description = "High-performance system-wide BPF-based workload tracer with Perfetto-backed trace visualization";
    homepage = "https://github.com/anakryiko/wprof";
    license = licenses.bsd3;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    mainProgram = "wprof";
  };
}
