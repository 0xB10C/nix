{ stdenv
, lib
, fetchFromGitHub
, pkg-config
, autoreconfHook
, cmake
, boost
, libevent
, libsystemtap
, version
, useCmake ? false
, ...
}:


stdenv.mkDerivation rec {
  pname = "bitcoind-${version}";
  name = "bitcoind-${version}";
  inherit version;

  src = fetchFromGitHub {
    owner = "bitcoin";
    repo = "bitcoin";
    rev = version;
    sha256 = {
      "v28.0" = "sha256-LLtw6pMyqIJ3IWHiK4P3XoifLojB9yMNMo+MGNFGuRY=";
      "v29.0" = "sha256-XvoqYA5RYXbOjeidxV4Wxb8DhYv6Hz510XNMhmWkV1Y=";
    }.${version} or (builtins.trace "Bitcoin Core using dummy vendor SHA256" "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=");
  };

  nativeBuildInputs = [
    pkg-config
    (if useCmake then cmake else autoreconfHook)
    libsystemtap
  ];
  buildInputs = [ boost libevent libsystemtap ];

  cmakeFlags = if useCmake then [
    (lib.cmakeBool "BUILD_BENCH" false)
    (lib.cmakeBool "WITH_ZMQ" false)
    (lib.cmakeBool "WITH_BDB" false)
    (lib.cmakeBool "WITH_USDT" true)
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
    "--enable-ebpf"
  ];

  doCheck = false;
  enableParallelBuilding = true;
}
