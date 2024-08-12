{ stdenv
, fetchFromGitHub
, pkg-config
, autoreconfHook
, boost
, libevent
, libsystemtap
, version
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
    }.${version} or (builtins.trace "Bitcoin Core using dummy vendor SHA256" "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=");
  };

  nativeBuildInputs = [ pkg-config autoreconfHook libsystemtap ];
  buildInputs = [ boost libevent libsystemtap ];

  configureFlags = [
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
