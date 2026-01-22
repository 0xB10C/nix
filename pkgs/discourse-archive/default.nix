{ lib
, python3
, fetchFromGitHub
}:

python3.pkgs.buildPythonPackage rec {
  pname = "discourse-archive";
  version = "01e298b049d0b6002280cdb67ffe770d58fcd161";

  pyproject = true;

  src = fetchFromGitHub {
    owner = "jamesob";
    repo = "discourse-archive";
    rev = version;
    hash = "sha256-1vpasjmp327vv8Cj883gYtxZmzRiKkPkCaw+F+sYgEM=";
  };

  build-system = with python3.pkgs; [
    setuptools
    wheel
  ];

  dependencies = with python3.pkgs; [];

  pythonRequires = ">=3.11";

  meta = with lib; {
    description = "Create a simple content archive from a Discourse site";
    homepage = "https://github.com/jamesob/discourse-archive";
    changelog = "https://github.com/jamesob/discourse-archive/releases";
    license = licenses.mit;
    mainProgram = "discourse-archive";
  };
}
