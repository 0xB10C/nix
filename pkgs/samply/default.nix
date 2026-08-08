{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "samply";
  version = "samply-symbols-v0.24.1-unstable-2026-08-05";

  src = fetchFromGitHub {
    owner = "mstange";
    repo = "samply";
    rev = "cd249936e3ffe70ec2c57e3f98cc1f571c89ff6d";
    hash = "sha256-bHqQTRf0Zl6aO5lPABKKjwDi2qMrMa8F+hhOuKa63Ag=";
  };

  cargoHash = "sha256-FnNHyIAdpmXsikgSqnZBjRa/E9ivDt/rd/S1WgtG/Do=";

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
