{ stdenv, pkgs, lib, rustPlatform, postgresql, ... }:

rustPlatform.buildRustPackage rec {
  pname = "stratum-observer";
  name = "stratum-observer";
  version = "b0cdc7af6bec2803271c7f8b4fc2ae60e0c995c9";

  src = pkgs.fetchFromGitHub {
    owner = "0xB10C";
    repo = "stratum-observer";
    rev = version;
    sha256 = "sha256-g2SmTcvTzYJSzkv3LrgFJsvRLpUf2l/ohx/zzYBYYhg=";
  };

  nativeBuildInputs = [ postgresql ];
  buildInputs = [ postgresql ];

  cargoHash = "sha256-RJwr41lTA0eJBRARQNoGoAAizi2mgcX60X6KKXccdPM=";

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
