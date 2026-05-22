{ stdenv, pkgs, lib, fetchFromBitbucket, autoreconfHook, yasm
, testers, zeromq, pkg-config, ... }:

stdenv.mkDerivation rec {
  pname = "ckpool";
  name = "ckpool";
  version = "v1.1.1";

  src = pkgs.fetchFromBitbucket {
    owner = "ckolivas";
    repo = "ckpool";
    rev = version;
    sha256 = "sha256-pEapAfid7AdwupNZUGguF5Meym5uuVMveghu93Jkx0s=";
  };

  nativeBuildInputs = [ autoreconfHook pkg-config zeromq yasm ];

  # a libjansson format check fails
  doCheck = false;

  patches = [
    # 'make install' tries to set setcap CAP_NET_BIND_SERVICE=+eip on the binary
    # We don't want or need that.
    ./make-install-no-setcap.patch
  ];

  passthru.tests.version = testers.testVersion {
    package = (pkgs.callPackage ./default.nix {});
    command = "ckpool --help";
    # testing that we can run the binary with the --help flag
    # it does not print a version
    version = "--config CONFIG";
  };

  meta = with stdenv.lib; {
    description = "Solo ckpool";
    longDescription = ''
      Ultra low overhead massively scalable multi-process, multi-threaded modular bitcoin mining pool, proxy, passthrough, and library in c for Linux.
    '';
    homepage = "https://bitbucket.org/ckolivas/ckpool-solo/src/solobtc/";
    license = lib.licenses.agpl3Only;
  };
}
