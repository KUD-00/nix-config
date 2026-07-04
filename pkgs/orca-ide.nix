# Orca — Agent Development Environment (ADE) for running parallel coding agents
# https://github.com/stablyai/orca
# Update: check the latest release tag, then update version + sha256
# (nix-prefetch-url the new AppImage URL).
{ lib, appimageTools, fetchurl }:

let
  pname = "orca-ide";
  version = "1.4.121";

  src = fetchurl {
    url = "https://github.com/stablyai/orca/releases/download/v${version}/orca-linux.AppImage";
    sha256 = "0zln8bd21897lgjyzsaazap20p7mjvhq7sqil6l3z4b0phrwdhwz";
  };

  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    # expose "orca" as the command name too
    ln -s $out/bin/${pname} $out/bin/orca

    if [ -f ${appimageContents}/orca.desktop ]; then
      install -Dm444 ${appimageContents}/orca.desktop $out/share/applications/orca-ide.desktop
      substituteInPlace $out/share/applications/orca-ide.desktop \
        --replace-quiet 'Exec=AppRun' 'Exec=orca'
    fi
    for icon in ${appimageContents}/usr/share/icons/hicolor/*/apps/*.png; do
      size=$(basename $(dirname $(dirname "$icon")))
      install -Dm444 "$icon" "$out/share/icons/hicolor/$size/apps/$(basename "$icon")"
    done
  '';

  meta = with lib; {
    description = "Orca - Agent Development Environment for parallel AI coding agents";
    homepage = "https://www.onorca.dev";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "orca";
  };
}
