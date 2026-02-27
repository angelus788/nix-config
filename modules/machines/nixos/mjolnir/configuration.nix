{ config, pkgs, lib, inputs, ... }:

{

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    networkmanager.enable = true;
    hostName = "mjolnir";
  };

  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };


  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  #services.displayManager.gdm.enable = true;
  #services.desktopManager.gnome.enable = true;

  # Enable Cosmic
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };


  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.fwupd.enable = true;

  programs.firefox.enable = true;

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [
    bitwarden-cli
    bitwarden-desktop
    brave
    #cosmic-polkit
    fprintd
    ghostty
    git
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    just
    nixos-rebuild-ng
    obsidian
    spotify
    stow
    #unstable.tailscale-gui #try again at a later date
    # variety
    vscodium
    wget
    zed-editor
  ];

  # 1Password
  programs = {
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "angelus" ];
    };
  };

  environment.etc = {
    "1password/custom_allowed_browsers" = {
      text = ''
        vivaldi-bin
        librewolf
        zen
      '';
      mode = "0755";
    };
  };

  programs.nix-ld.enable = true;

  services.fprintd = {
    enable = true;
    tod.enable = false; # T490 Synaptics does NOT use TOD driver
  };

  security.pam.services = {
    login.fprintAuth = true;
    sudo.fprintAuth = true;
    cosmic-greeter.fprintAuth = true;
    cosmic-lock.fprintAuth = true;
    cosmic-settings.fprintAuth = true;
  };

  security.polkit.enable = true;

  imports =
    [
      inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t490
      ./secrets
      ./hardware-configuration.nix
      #../_common/apps/vscodium
      ../_common/apps/tailscale
    ];

}
