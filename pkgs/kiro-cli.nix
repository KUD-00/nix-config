{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, zlib
, buildFHSEnv
, openssl
, icu
, xz
, bzip2
}:

let
  pname = "kiro-cli";
  version = "1.21.0";

  unwrapped = stdenv.mkDerivation {
    pname = "${pname}-unwrapped";
    inherit version;

    src = fetchurl {
      # Use the Glibc variant as per AUR (matches official distribution better than Musl for FHS)
      url = "https://desktop-release.q.us-east-1.amazonaws.com/${version}/kirocli-x86_64-linux.tar.gz";
      sha256 = "48bf31133ff2e4098002699e8b29a0bdb6397273c8f2e57de3b1e7f5f610b6cc";
    };

    nativeBuildInputs = [
      autoPatchelfHook
    ];

    buildInputs = [
      zlib
      stdenv.cc.cc.lib
      xz
      bzip2
    ];

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      
      # Install all binaries as per AUR
      install -m755 kirocli/bin/kiro-cli $out/bin/kiro-cli
      install -m755 kirocli/bin/kiro-cli-chat $out/bin/kiro-cli-chat
      install -m755 kirocli/bin/kiro-cli-term $out/bin/kiro-cli-term
      install -m755 kirocli/bin/q $out/bin/q
      install -m755 kirocli/bin/qchat $out/bin/qchat

      # Patch the wrapper scripts 'q' and 'qchat' to point to the correct binary location
      # The original scripts point to $HOME/.local/bin/kiro-cli
      # We point them to the binary in the current path (which will be inside FHS)
      sed -i "s|\$HOME/.local/bin/kiro-cli|kiro-cli|g" $out/bin/q $out/bin/qchat

      runHook postInstall
    '';
  };
in
buildFHSEnv {
  name = pname;
  inherit version;

  targetPkgs = pkgs: with pkgs; [
    zlib
    openssl
    icu
    stdenv.cc.cc.lib
    # Common tools that the agent might need
    git
    curl
    less
    # Basic utils
    coreutils
    bash
    which
  ];

  # Symlink all the binaries from the unwrapped derivation
  extraBuildCommands = ''
    mkdir -p $out/usr/bin
    ln -s ${unwrapped}/bin/kiro-cli $out/usr/bin/kiro-cli
    ln -s ${unwrapped}/bin/kiro-cli-chat $out/usr/bin/kiro-cli-chat
    ln -s ${unwrapped}/bin/kiro-cli-term $out/usr/bin/kiro-cli-term
    ln -s ${unwrapped}/bin/q $out/usr/bin/q
    ln -s ${unwrapped}/bin/qchat $out/usr/bin/qchat
  '';

  runScript = "kiro-cli";

  meta = with lib; {
    description = "Kiro AI CLI (Agentic IDE helper) - Headless";
    homepage = "https://kiro.dev";
    license = licenses.unfree;
    maintainers = [ ];
    platforms = [ "x86_64-linux" ];
  };
}
