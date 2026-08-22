{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "samply";
  version = "samply-symbols-v0.24.1-unstable-2026-08-20";

  src = fetchFromGitHub {
    owner = "mstange";
    repo = "samply";
    rev = "7003392bdcdd78d7c8fa115c306408abf54a0e1a";
    hash = "sha256-lEVgR7pi8aJsGdLO11VCY5NaYPPAx7fvPAwjNTXKDF4=";
  };

  cargoHash = "sha256-ph7RSTyjNJjboLM2Eq9AIeS91rrwkWUSMINknqOIFE4=";

  meta = {
    description = "Command line profiler for macOS and Linux";
    homepage = "https://github.com/mstange/samply";
    license = with lib.licenses; [
      asl20
      mit
    ];
    maintainers = [ ];
    mainProgram = "samply";
  };
})
