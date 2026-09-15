{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "samply";
  version = "samply-symbols-v0.24.1-unstable-2026-09-15";

  src = fetchFromGitHub {
    owner = "mstange";
    repo = "samply";
    rev = "749a1f814704611e0cb6f8da90cb296835e14ada";
    hash = "sha256-vrwkm1gYeeA4/XYHTu1bhfZle5VxS8AvIjkQzOlcfCw=";
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
