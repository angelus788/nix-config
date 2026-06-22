{ pkgs, inputs, ... }:

{

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    networkmanager.enable = true;
    hostName = "mjolnir";
  };
  
  services.flatpak.enable = true;


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


  environment.systemPackages = with pkgs; [
    pkgs.android-tools
    bitwarden-cli
    bitwarden-desktop
    claude-code
    google-chrome
    brave
    #cosmic-polkit
    fprintd
    ghostty
    git
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    just
    obsidian
    proton-pass
    spotify
    #rquickshare
    stow
    thunderbird
    unstable.proton-pass-cli
    #unstable.tailscale-gui #try again at a later date
    variety
    vscodium
    wget
    zed-editor
    zola
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

  home-manager.users.angelus.myHomeDots.enableGui = true;

  syncthingSettings = {
    guiPassword = "$2b$05$Xl3P7nFnclVkHhkbRJjsAeOwsIP3O.2mvdQGm3jKUAwqWH72CDagC";
    folders = {
      Documents.path = "/home/angelus/Documents";
      Homework.path = "/home/angelus/Homework";
      remarkable_sync.path = "/home/angelus/remarkable_sync";
      pdf2remarkable.path = "/home/angelus/pdf2remarkable";
    };
  };

  imports = [
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t490
    inputs.lanzaboote.nixosModules.lanzaboote
    ./secrets
    ./hardware-configuration.nix
    ../../../apps/tailscale
    ../../../apps/DE/cosmic
    #../../../apps/DE/gnome
    #../../../apps/DE/plasma
    #../../../misc/papery
    ../../../apps/wpaperd
    ../../../misc/syncthing
  ];

}
