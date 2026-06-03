{
  inputs,
  pkgs,
  ...
}:
{
  system.primaryUser = "angelus";
  environment.shellInit = ''
    ulimit -n 2048
  '';

  imports = [
    #"${inputs.secrets}/work.nix"
    ./secrets.nix
  ];

  #devShells.aarch64-darwin.default
  #packages.aarch64-darwin.default
  #legacyPackages.aarch64-darwin.default

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
      upgrade = true;
    };
    brewPrefix = "/opt/homebrew/bin";
    caskArgs = {
      no_quarantine = true;
    };
    brews = [
      "mas"
      "pulumi"
    ];
    casks = [
      "1password"
      "1password-cli"
      "element"
      "eqmac"
      "firefox"
      "ghostty"
      "google-chrome"
      "grid"
      "handbrake-app"
      "libreoffice"
      "little-snitch"
      #"monitorcontrol"
      "notion"
      "pocket-casts"
      "proton-pass"
      "raycast"
      "signal"
      "soundsource"
      "spotify"
      "tailscale-app"
      "thunderbird"
      "telegram"
      "todoist-app"
      "ungoogled-chromium"
      "zen"
    ];
    masApps = {
      "Amphetamine" = 937984704;
      "Signal Shifter" = 6446061552;
      #"Yoink" = 457622435;
    };
    #onActivation.cleanup = "zap";
    #onActivation.autoUpdate = "false";
    #onActivation.upgrade = "true";
  };

  environment.systemPackages = with pkgs; [
    (python312.withPackages (
      ps: with ps; [
        pip
        jmespath
        requests
        setuptools
        pyyaml
        pyopenssl
      ]
    ))
    ansible
    ansible-lint
    bitwarden-cli
    bitwarden-desktop
    brave
    ddev
    deploy-rs
    devenv
    docker
    docker-buildx
    docker-compose
    eza
    fastfetch
    git
    git-crypt
    git-lfs
    gnupg
    inputs.agenix.packages."${stdenv.hostPlatform.system}".default
    just
    karabiner-elements
    kubectl
    kustomize
    librewolf
    mkalias
    nil
    nss
    nss.tools
    nixfmt
    nixos-rebuild
    nixos-rebuild-ng
    nixpkgs-fmt
    obsidian
    packer
    ripgrep
    rsync
    stow
    tmux
    vim
    vscode
    vscodium
    wget
    zola
  ];

  fonts.packages = [
    pkgs.nerd-fonts.jetbrains-mono
    #(pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  ids.gids.nixbld = 350;

  networking.hostName = "tyr";

  system.stateVersion = 4;
}
