# Grok Build — xAI's coding agent CLI (beta)
# Update: check `curl -fsSL https://x.ai/cli/stable` for the latest version,
# then update version + sha256 below.
{ lib, stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "grok-build";
  version = "0.2.82";

  src = fetchurl {
    url = "https://x.ai/cli/grok-${version}-linux-x86_64";
    sha256 = "c74faf275141e16548802418ebf10763947ebaa00f2427bb80f022aba63688fe";
  };

  dontUnpack = true;
  dontStrip = true; # statically linked, nothing to patch

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/grok
    runHook postInstall
  '';

  meta = with lib; {
    description = "Grok Build - xAI's coding agent CLI";
    homepage = "https://x.ai/news/grok-build-cli";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "grok";
  };
}
