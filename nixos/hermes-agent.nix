{ config, lib, pkgs, inputs, ... }:

let
  src = inputs.hermes-agent.outPath;
  uv2nix = inputs.hermes-agent.inputs.uv2nix;
  pyproject-nix = inputs.hermes-agent.inputs.pyproject-nix;
  pyproject-build-systems = inputs.hermes-agent.inputs.pyproject-build-systems;

  workspace = uv2nix.lib.workspace.loadWorkspace {
    workspaceRoot = src;
  };

  hacks = pkgs.callPackage pyproject-nix.build.hacks { };

  overlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };

  mkPrebuiltPassthru = dependencies: {
    inherit dependencies;
    optional-dependencies = { };
    dependency-groups = { };
  };

  mkPrebuiltOverride = final: from: dependencies:
    hacks.nixpkgsPrebuilt {
      inherit from;
      prev = {
        nativeBuildInputs = [ final.pyprojectHook ];
        passthru = mkPrebuiltPassthru dependencies;
      };
    };

  pythonPackageOverrides = final: prev:
    let
      addSetuptools = pkg:
        pkg.overrideAttrs (old: {
          nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.setuptools ];
        });
      isAarch64Darwin = pkgs.stdenv.hostPlatform.system == "aarch64-darwin";
    in
    {
      # matrix-nio[e2e] pulls atomicwrites from sdist without setuptools metadata.
      atomicwrites = mkPrebuiltOverride final pkgs.python311.pkgs.atomicwrites { };

      # These Alibaba sdists have setup.cfg/setup.py only and omit setuptools.
      alibabacloud-credentials-api = addSetuptools prev.alibabacloud-credentials-api;
      alibabacloud-endpoint-util = addSetuptools prev.alibabacloud-endpoint-util;
      alibabacloud-gateway-dingtalk = addSetuptools prev.alibabacloud-gateway-dingtalk;
      alibabacloud-gateway-spi = addSetuptools prev.alibabacloud-gateway-spi;
      alibabacloud-tea = addSetuptools prev.alibabacloud-tea;
    } // lib.optionalAttrs isAarch64Darwin {
      numpy = mkPrebuiltOverride final pkgs.python311.pkgs.numpy { };

      av = mkPrebuiltOverride final pkgs.python311.pkgs.av { };

      humanfriendly = mkPrebuiltOverride final pkgs.python311.pkgs.humanfriendly { };

      coloredlogs = mkPrebuiltOverride final pkgs.python311.pkgs.coloredlogs {
        humanfriendly = [ ];
      };

      onnxruntime = mkPrebuiltOverride final pkgs.python311.pkgs.onnxruntime {
        coloredlogs = [ ];
        numpy = [ ];
        packaging = [ ];
      };

      ctranslate2 = mkPrebuiltOverride final pkgs.python311.pkgs.ctranslate2 {
        numpy = [ ];
        pyyaml = [ ];
      };

      faster-whisper = mkPrebuiltOverride final pkgs.python311.pkgs.faster-whisper {
        av = [ ];
        ctranslate2 = [ ];
        huggingface-hub = [ ];
        onnxruntime = [ ];
        tokenizers = [ ];
        tqdm = [ ];
      };
    };

  pythonSet =
    (pkgs.callPackage pyproject-nix.build.packages {
      python = pkgs.python311;
    }).overrideScope
      (lib.composeManyExtensions [
        pyproject-build-systems.overlays.default
        overlay
        pythonPackageOverrides
      ]);

  hermesVenv = pythonSet.mkVirtualEnv "hermes-agent-env" {
    hermes-agent = [ "all" ];
  };

  bundledSkills = lib.cleanSourceWith {
    src = src + "/skills";
    filter = path: _type:
      !(lib.hasInfix "/index-cache/" path);
  };

  runtimePath = lib.makeBinPath [
    pkgs.nodejs_22
    pkgs.ripgrep
    pkgs.git
    pkgs.openssh
    pkgs.ffmpeg
    pkgs.tirith
  ];

  hermes-agent-package = pkgs.stdenv.mkDerivation {
    pname = "hermes-agent";
    version = (builtins.fromTOML (builtins.readFile (src + "/pyproject.toml"))).project.version;

    dontUnpack = true;
    dontBuild = true;
    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/hermes-agent $out/bin
      cp -r ${bundledSkills} $out/share/hermes-agent/skills

      ${lib.concatMapStringsSep "\n" (name: ''
        makeWrapper ${hermesVenv}/bin/${name} $out/bin/${name} \
          --suffix PATH : "${runtimePath}" \
          --set HERMES_BUNDLED_SKILLS $out/share/hermes-agent/skills
      '') [ "hermes" "hermes-agent" "hermes-acp" ]}

      runHook postInstall
    '';

    meta = with lib; {
      description = "AI agent with advanced tool-calling capabilities";
      homepage = "https://github.com/NousResearch/hermes-agent";
      mainProgram = "hermes";
      license = licenses.mit;
      platforms = platforms.unix;
    };
  };
in
{
  imports = [
    inputs.hermes-agent.nixosModules.default
  ];

  sops = {
    defaultSopsFile = ../secrets.enc.yaml;
    age.keyFile = "/home/kud/.config/sops/age/keys.txt";
    secrets.minimax_api_key = { };
    templates.hermes-agent-env = {
      content = ''
        MINIMAX_API_KEY=${config.sops.placeholder.minimax_api_key}
      '';
    };
  };

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    package = hermes-agent-package;
    environmentFiles = [ config.sops.templates.hermes-agent-env.path ];
    settings = {
      model = {
        provider = "minimax";
        default = "MiniMax-M2.7";
      };
      terminal.backend = "local";
    };
  };
}
