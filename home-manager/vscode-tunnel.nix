{ config, pkgs, hostname, ... }:

{
  systemd.user.services.vscode-tunnel = {
    Unit = {
      Description = "VS Code Tunnel";
      After = [ "network.target" ];
    };

    Service = {
      # The script defaults to "Lain" if VSCODE_TUNNEL_NAME is not set, 
      # but we want it to match the machine hostname.
      Environment = "VSCODE_TUNNEL_NAME=${hostname} VSCODE_TUNNEL_LOG=info PATH=${config.home.homeDirectory}/.nix-profile/bin:/run/current-system/sw/bin:/usr/bin:/bin";
      ExecStart = "${pkgs.bash}/bin/bash %h/nix-config/scripts/vscode-tunnel.sh start";
      ExecStop = "${pkgs.bash}/bin/bash %h/nix-config/scripts/vscode-tunnel.sh stop";
      Restart = "always";
      RestartSec = "10";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
