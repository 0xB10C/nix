{ stdenv, pkgs, lib, rustPlatform, ... }:

rustPlatform.buildRustPackage rec {
  pname = "addrman-observer-proxy";
  name = "addrman-observer-proxy";
  version = "779291c38ac9dd7bceabe9334131a1e188f171ed";

  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "addrman-observer";
    rev = version;
    sha256 = "sha256-tOn9WRrSkC6M+WiMRF55NxRk3wgF6BxApapfb7pocBk=";
  };

  sourceRoot = "source/proxy";

  cargoLock = {
    lockFile = ./Cargo.lock;
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
