{ stdenv, pkgs, lib, fetchFromBitbucket, autoreconfHook, yasm
, testers, zeromq, pkg-config, ... }:

stdenv.mkDerivation rec {
  pname = "ckpool";
  name = "ckpool";
  version = "v0.9.9";

  src = pkgs.fetchFromBitbucket {
    owner = "ckolivas";
    repo = "ckpool-solo";
    rev = version;
    sha256 = "sha256-kCZ9ILaFVQC1xvG7a14tHUVeGY9KuZEnvhNXRibDBms=";
  };

  nativeBuildInputs = [ autoreconfHook pkg-config zeromq yasm ];

  # a libjansson format check fails
  doCheck = false;

  patches = [
    # 'make install' tries to set setcap CAP_NET_BIND_SERVICE=+eip on the binary
    # We don't want or need that.
    ./make-install-no-setcap.patch
  ];

  configureFlags = [
    # needed for libjansson.a
    "--enable-static"
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
