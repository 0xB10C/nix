{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "samply";
  version = "samply-symbols-v0.24.1-unstable-2026-10-18";

  src = fetchFromGitHub {
    owner = "mstange";
    repo = "samply";
    rev = "0e9e915ca9317b8cef0152b3a7508cfeea1ba44a";
    hash = "sha256-66P6ufjSa412r53enBqC+EfG0+OjkKBZeXy2afIpQ+k=";
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
