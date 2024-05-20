{ stdenv, pkgs, lib, rustPlatform, postgresql, ... }:

rustPlatform.buildRustPackage rec {
  pname = "stratum-observer";
  name = "stratum-observer";
  version = "a972a7cace5dd58e6b3663952ee5c28231e379b5";

  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "stratum-observer";
    rev = version;
    sha256 = "sha256-mRWslBhJP2LNfGvV532WaF+xxfgQxoqaIBKNRjLNG8g=";
  };

  nativeBuildInputs = [ postgresql ];
  
  cargoSha256 = "sha256-cH7oMXCrB4uqLZNDM7vf4xIf4IpkZQK4zBgrcf6dQ0s=";

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
