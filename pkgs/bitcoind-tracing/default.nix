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
      "v23.2" = "sha256-iE247MKKzY5yB7ihbVJ9sBtciFJ84bSZhd4URthrJqM=";
      "v24.2" = "sha256-ndr1JqwERKBQzKB0xgIOUC2+bF43IlajCAnIieZBNr0=";
      "v25.2" = "sha256-BzND0AE7Xhf/pX2jedoPIHk3J77IwOpZ2WOzaYiZyzE=";
      "v26.2" = "sha256-hXE9FVb4Fnz0DofQfkVp08p15qvhdGc6+eQ6P4IJVhE=";
      "v27.1" = "sha256-1Gpesss4MTiU3Omi/scDV0iU2de4j/oDIY3Y5H2KQp4=";
      "v27.2" = "sha256-E0+3tON+uIkqN+QEmZZSEfDCDcCdYtJjfhcDFYs1zH4=";
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
