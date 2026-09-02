{ pkgs, inputs, lib, ... }:

{

  # Upstream nixpkgs bug: netbird-ui's own .desktop Exec line is now
  # `env WEBKIT_DISABLE_DMABUF_RENDERER=1 netbird-ui`, but the netbird NixOS
  # module's wrapper still substitutes the literal `Exec=netbird-ui`, so
  # --replace-fail aborts the build with "pattern doesn't match". ui.enable
  # defaults to true on any host with a graphical session (cosmic here) -
  # disable it until nixpkgs catches up. The CLI/daemon/tunnel work fine
  # without the tray icon.
  services.netbird.ui.enable = false;

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

  #programs.firefox.enable = true;


  environment.systemPackages = with pkgs; [
    pkgs.android-tools
    claude-code
    cifs-utils
    google-chrome
    bitwarden-desktop
    brave
    #cosmic-polkit
    fprintd
    git
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    just
    obsidian
    proton-pass
    rustdesk
    spotify
    #rquickshare
    seahorse
    stow
    thunderbird
    unstable.proton-pass-cli
    #unstable.tailscale-gui #try again at a later date
    vscodium
    wget
    zola
  ];




  programs.nix-ld.enable = true;

  services.fprintd = {
    enable = true;
    tod.enable = false; # T490 Synaptics does NOT use TOD driver
  };

  # power-profiles-daemon runtime-suspends the Synaptics fingerprint reader
  # (USB 06cb:*) after 2s idle; libfprint doesn't always wake it in time,
  # causing "No such device" / "device is still busy" errors from fprintd
  # and the slow/unreliable scans seen here vs. Arch on the same hardware.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="06cb", TEST=="power/control", ATTR{power/control}="on"
  '';

  security.pam.services = {
    login.fprintAuth = true;
    sudo.fprintAuth = true;
    polkit-1.fprintAuth = true; # ← This is the bridge Bitwarden needs
    cosmic-greeter = {
      # fprintAuth defaults to config.services.fprintd.enable (true here), so
      # merely omitting it still wires pam_fprintd.so in as "sufficient"
      # ahead of pam_unix - a fingerprint login short-circuits the auth stack
      # and pam_unix never runs, meaning pam_gnome_keyring never sees the
      # login password and the keyring stays locked all session. Must be
      # explicitly false. Password-only at the greeter is what actually
      # unlocks it; fingerprint still works everywhere else (lock, sudo,
      # polkit) once the keyring is unlocked for the session.
      fprintAuth = false;
      enableGnomeKeyring = true;
    };
    cosmic-lock = {
      fprintAuth = true;
      enableGnomeKeyring = true;
    };
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
    ./boot.nix
    ./disks.nix
    ./hardware-configuration.nix
    ../../../apps/1password
    ../../../apps/DE/cosmic
    #../../../apps/DE/gnome
    #../../../apps/DE/plasma
    ../../../apps/openpuck
    ../../../apps/packet
    #../../../misc/papery
    #../../../apps/wpaperd
    ../../../apps/smbshared
    ../../../misc/syncthing
    ../../../apps/netbird
  ];

}
