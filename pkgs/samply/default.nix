{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "samply";
  version = "samply-symbols-v0.24.1-unstable-2026-10-24";

  src = fetchFromGitHub {
    owner = "mstange";
    repo = "samply";
    rev = "99fe90353baeca4b50e71ea6ec83a03643f888ff";
    hash = "sha256-EF9O15sJVvCAP1FHZd/F8GfNKbqQ9TVd7jV9zsxep08=";
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
