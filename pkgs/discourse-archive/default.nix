{ lib
, python3
, fetchFromGitHub
}:

python3.pkgs.buildPythonPackage rec {
  pname = "discourse-archive";
  version = "760becb61376f5149bf88b7e1393081e3ef14ae7";

  pyproject = true;

  src = fetchFromGitHub {
    owner = "0xB10C";
    repo = "discourse-archive";
    rev = version;
    hash = "sha256-M5QdGTQphrMVGD1X3RtKS+fvRRNdPiKUVwHWrhZ7+pI=";
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

  # We pin to a git revision and use the commit hash as the version, which
  # isn't a PEP 440 version, so nixpkgs' pythonMetadataCheckPhase can't parse
  # it and fails. It also couldn't match upstream's pyproject.toml version.
  dontCheckPythonMetadata = true;

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
