{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "samply";
  version = "samply-symbols-v0.24.1-unstable-2026-09-30";

  src = fetchFromGitHub {
    owner = "mstange";
    repo = "samply";
    rev = "247df8fe0fa259ddb5e671bfe3121728e0d6119d";
    hash = "sha256-jzebmwx1d17zve2jPIX23oEPlTayJxvZLEED4nSe20w=";
  };

  cargoHash = "sha256-6oVURNVZI7Bw8y4R8Xn/+EHibQQ1nMrM/xzWhq7baZk=";

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
