{ stdenv, pkgs, lib, rustPlatform, ... }:

rustPlatform.buildRustPackage rec {
  pname = "addrman-observer-proxy";
  name = "addrman-observer-proxy";
  version = "f14b6b2fdd6849217cdd7c70c0010606facb1d85";

  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "addrman-observer";
    rev = version;
    sha256 = "sha256-Zb+xDnLi42FjG/5R5PvY0eAsnn7U8iCkpXd5hxd7OuY=";
  };

  sourceRoot = "source/proxy";

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "bitcoincore-rpc-0.17.0" = "sha256-AYnzu/glqD9TXHXdnXCQqOwqbjiGM1LaPvBidDpykXM=";
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
