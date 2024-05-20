{ stdenv, pkgs, lib, rustPlatform, postgresql, ... }:

rustPlatform.buildRustPackage rec {
  pname = "stratum-observer";
  name = "stratum-observer";

  src = builtins.fetchGit {
    url = "git@github.com:0xB10C/stratum-observer.git";
    rev = "6f28d4324dbea160fd23b33d02e1853372a04c36";
    ref = "2024-06-psql-support";
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
