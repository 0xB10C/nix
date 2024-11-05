{ stdenv, pkgs, lib, rustPlatform, postgresql, ... }:

rustPlatform.buildRustPackage rec {
  pname = "stratum-observer";
  name = "stratum-observer";
  version = "978d3f4b29642acb44f14bf9fb7c7ec93041a583";

  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "stratum-observer";
    rev = version;
    sha256 = "sha256-FzjgRdpr1HPE2jMgZlqvS7fj7YlpA2MYpuR55IsUv30=";
  };

  nativeBuildInputs = [ postgresql ];
  
  cargoHash = "sha256-cH7oMXCrB4uqLZNDM7vf4xIf4IpkZQK4zBgrcf6dQ0s=";

  postInstall = ''
    cp -r www $out/www
  '';
  
  meta = with stdenv.lib; {
    description = "Tool for monitoring mining pool stratum jobs.";
    longDescription = ''
      The stratum-observer connects to Bitcoin mining pool stratum endpoints
      and listens on the work they are sending out. The work can be recorded
      and displayed with the stratum-observer. 
    '';
    homepage = "https://github.com/0xb10c/stratum-observer";
    license = lib.licenses.mit;
  };
}
