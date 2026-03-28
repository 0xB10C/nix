{ lib
, python3
, fetchFromGitHub
}:

python3.pkgs.buildPythonPackage rec {
  pname = "discourse-archive";
  version = "2360cd36a6da1b298d173d217947660624cf341e";

  pyproject = true;

  src = fetchFromGitHub {
    owner = "0xB10C";
    repo = "discourse-archive";
    rev = version;
    hash = "sha256-U8BNWdJuyYA4efpkvfzL1tbWNmac+5E+bqzku7F1QhE=";
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
