{ lib
, python3
, fetchFromGitHub
}:

python3.pkgs.buildPythonPackage rec {
  pname = "discourse-archive";
  version = "8cae8ceb86d588d37cb43e68e04ecbd79cbd5b68";

  pyproject = true;

  src = fetchFromGitHub {
    owner = "0xB10C";
    repo = "discourse-archive";
    rev = version;
    hash = "sha256-nY4cZ/fOxgVe1vGBleoEvoYQr2SAeDi7MXFWLiONipE=";
  };

  # The repo uses a flat layout with multiple top-level modules (archive.py
  # and mirror.py), which setuptools refuses to auto-discover. Declare the
  # modules explicitly and expose mirror.py as its own console script.
  postPatch = ''
    cat >> pyproject.toml <<'EOF'
discourse-mirror = "mirror:main"

[tool.setuptools]
py-modules = ["archive", "mirror"]
EOF
  '';

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
