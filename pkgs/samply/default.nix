{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "samply";
  version = "samply-symbols-v0.24.1-unstable-2026-10-05";

  src = fetchFromGitHub {
    owner = "mstange";
    repo = "samply";
    rev = "f5a8bf100cd54b771897f400b438c415f7d0f205";
    hash = "sha256-tp6BBaIfG2/4sTcKUEM6vmtg4fSwGT+dWbP7XptUBT8=";
  };

  cargoHash = "sha256-pncRQ0ZCw7ZUZvxZ9mSaZA8kOrvM1oQwHAG+6eQ6K0c=";

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
