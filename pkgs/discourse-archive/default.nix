{ lib
, python3
, fetchFromGitHub
}:

python3.pkgs.buildPythonPackage rec {
  pname = "discourse-archive";
  version = "93061b09f9d5fbaaeaa0261300302e069563cc22";

  pyproject = true;

  src = fetchFromGitHub {
    owner = "0xB10C";
    repo = "discourse-archive";
    rev = version;
    hash = "sha256-YIiSFjCu31BQlVeANGp3WhX5MtgcueSQiBDBdmla0cE=";
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
