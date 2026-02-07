{ config, inputs, lib, hostname, ... }:

let
  enableOpenclaw = false;
  steipeteToolsSource =
    let
      lock = builtins.fromJSON (builtins.readFile ../flake.lock);
      nodeName = lock.nodes.root.inputs.nix-steipete-tools or "nix-steipete-tools";
      node = lock.nodes.${nodeName};
      locked = node.locked;
      encode = s: builtins.replaceStrings ["+" "="] ["%2B" "%3D"] s;
      base = "${locked.type}:${locked.owner}/${locked.repo}";
      dirPart = if locked ? dir then "?dir=${locked.dir}" else "";
      sep = if dirPart == "" then "?" else "&";
    in
      "${base}${dirPart}${sep}rev=${locked.rev}&narHash=${encode locked.narHash}";
in
if enableOpenclaw then {
  imports = [ inputs.nix-openclaw.homeManagerModules.openclaw ];

  sops.secrets = lib.mkIf enableOpenclaw {
    telegram_bot_token = {};
    openclaw_env = {};
  };

  programs.openclaw = lib.mkIf enableOpenclaw {
    enable = true;
    config = {
      channels.telegram = {
        tokenFile = config.sops.secrets.telegram_bot_token.path;
        allowFrom = [ 12345678 ];
        groups = {
          "*" = { requireMention = true; };
        };
      };
    };
    plugins = [
      { source = steipeteToolsSource; }
    ];
  };

  systemd.user.services = lib.mkIf enableOpenclaw {
    openclaw-gateway.Service.EnvironmentFile = [
      config.sops.secrets.openclaw_env.path
    ];
  };
} else {}
