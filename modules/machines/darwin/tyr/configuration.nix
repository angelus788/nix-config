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
    #./netbird.nix
    ./secrets.nix
    ./tailscale.nix
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
      extraFlags = [ "--force" ];
    };

    prefix = "/opt/homebrew";
    #caskArgs = {
    #  no_quarantine = true;
    #};

    brews = [
      "mas"
      "pulumi"
      "tailscale"
    ];
    casks = [
      "1password"
      "1password-cli"
      "bitwarden"
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
      "obsidian"
      "pocket-casts"
      "proton-pass"
      "raycast"
      "signal"
      "soundsource"
      "spotify"
      #"tailscale-app"
      "thunderbird"
      "telegram"
      "todoist-app"
      "ungoogled-chromium"
      "zen"
    ];
    masApps = {
      "Amphetamine" = 937984704;
      #"Bitwarden" = 1352778147;
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
    #bitwarden-desktop #was not building under 26.05 (try later)
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
    kubectl
    kustomize
    #librewolf #was not building under 26.05 (try later)
    mkalias
    nil
    nss
    nss.tools
    nixfmt
    nixos-rebuild
    nixos-rebuild-ng
    nixpkgs-fmt
    #obsidian
    packer
    ripgrep
    rsync
    stow
    tmux
    vim
    vscodium
    wget
    zola
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "electron-39.8.10"
  ];

  fonts.packages = [
    pkgs.nerd-fonts.jetbrains-mono
    #(pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  ids.gids.nixbld = 350;

  home-manager.users.angelus.myHomeDots.enableGui = true;

  networking.hostName = "tyr";

  system.stateVersion = 4;
}
