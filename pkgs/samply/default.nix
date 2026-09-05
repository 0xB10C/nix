{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "samply";
  version = "samply-symbols-v0.24.1-unstable-2026-08-27";

  src = fetchFromGitHub {
    owner = "mstange";
    repo = "samply";
    rev = "a2252a6ef2ec2c9c77337b71644be58c93c7c6a8";
    hash = "sha256-uaCPOtiF4hPbCXDEOllpH4r9OE/+9igu4dbMjueu5rc=";
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
