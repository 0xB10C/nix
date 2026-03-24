{ stdenv, pkgs, lib, rustPlatform, ... }:

rustPlatform.buildRustPackage rec {
  pname = "addrman-observer-proxy";
  name = "addrman-observer-proxy";
  version = "d245e0758044175c6ebde96d4fa9ee1244fe4a60";

  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "addrman-observer";
    rev = version;
    sha256 = "sha256-d48UzE+5kWY0OLILni8toYNf/6HBP60oA6tTpieA/k8=";
  };

  sourceRoot = "source/proxy";

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "bitreq-0.3.1" = "sha256-0iy49rQSM23XFqS2QUKh1DH0qRbiZsvdWuC5DDpDVB4=";
    };
  };

  postInstall = ''
    cp -r ${src}/www $out/www
  '';

  meta = with stdenv.lib; {
    description = "RPC to REST proxy for the Bitcoin Core getrawaddrman RPC call.";
    longDescription = ''
      The addrman-observer can be hooked up to one or more Bitcoin Core nodes via
      the RPC interface. It proxies the `getrawaddrman` RPC server and hosts the
      static HTML files of the addrman-observer frontend. The proxy allows CORS
      requests.
    '';
    homepage = "https://github.com/0xb10c/addrman-observer";
    license = lib.licenses.mit;
  };
}
