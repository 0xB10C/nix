{ stdenv
, lib
, fetchFromGitHub
, pkg-config
, autoreconfHook
, cmake
, boost
, libevent
, libsystemtap
, capnproto
, version
, useCmake ? false
, enableTracing ? stdenv.hostPlatform.isLinux && !stdenv.hostPlatform.isStatic
, ...
}:

let
  needsCapnp = lib.versionAtLeast (lib.removePrefix "v" version) "30.0";
in
stdenv.mkDerivation rec {
  pname = "bitcoind-${version}";
  name = "bitcoind-${version}";
  inherit version;

  src = fetchFromGitHub {
    owner = "bitcoin";
    repo = "bitcoin";
    rev = version;
    sha256 = {
      "v29.4" = "sha256-nZykmmGn5RwSe11OXN8urjnq0TwcG6aZGDexgkmGAxM=";
      "v30.3" = "sha256-ODNa3jzE6gGLfvEX3e7tFe9mtbQUo4+qK2s0L2OKH1Q=";
      "v31.1" = "sha256-Hk0RBqSlJvCe5IOPCKBj0K3CyJf9U9m9DpfkpOL09X4=";
    }.${version} or (builtins.trace "Bitcoin Core using dummy vendor SHA256" "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=");
  };

  nativeBuildInputs = [
    pkg-config
    (if useCmake then cmake else autoreconfHook)
  ] ++ lib.optionals needsCapnp [ capnproto ]
    ++ lib.optionals enableTracing [ libsystemtap ];
  buildInputs = [
    boost
    libevent
  ] ++ lib.optionals enableTracing [ libsystemtap ];

  cmakeFlags = if useCmake then [
    (lib.cmakeBool "BUILD_BENCH" false)
    (lib.cmakeBool "WITH_ZMQ" false)
    (lib.cmakeBool "WITH_BDB" false)
    (lib.cmakeBool "WITH_USDT" enableTracing)
    (lib.cmakeBool "BUILD_TESTS" false)
    (lib.cmakeBool "BUILD_FUZZ_BINARY" false)
    (lib.cmakeBool "BUILD_GUI_TESTS" false)
    (lib.cmakeBool "ENABLE_WALLET" false)
    (lib.cmakeBool "BUILD_GUI" false)
  ] else [];

  configureFlags = if useCmake then [] else [
    "--with-boost-libdir=${boost.out}/lib"
    "--disable-shared"
    "--disable-wallet"
    "--disable-bench"
    "--disable-tests"
    "--enable-fuzz-binary=no"
  ] ++ lib.optionals enableTracing [ "--enable-ebpf" ];

  doCheck = false;
  enableParallelBuilding = true;
}
