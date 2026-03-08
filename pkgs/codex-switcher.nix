{ lib, appimageTools, fetchurl }:

appimageTools.wrapType2 {
  pname = "codex-switcher";
  version = "0.1.0";

  src = fetchurl {
    url = "https://github.com/Lampese/codex-switcher/releases/download/v0.0.4/Codex.Switcher_0.1.0_amd64.AppImage";
    hash = "sha256-Y1YYrQSyQILEnIVuw2gkO1jT25eP9GLjXXmaojDbOrI=";
  };

  meta = with lib; {
    description = "Desktop application for managing multiple OpenAI Codex CLI accounts";
    homepage = "https://github.com/Lampese/codex-switcher";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "codex-switcher";
  };
}
