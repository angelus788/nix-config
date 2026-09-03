{ pkgs, inputs, ... }:

{
  _module.args.disks = [ "/dev/nvme0n1" ];

  # Upstream nixpkgs bug: by the time netbird-ui finishes building, its own
  # .desktop file's Exec= line is already an absolute store path, but the
  # netbird NixOS module's wrapper still does `--replace-fail 'Exec=netbird-ui'`
  # against it, so the substitution never matches and the build aborts.
  # ui.enable defaults to true on any host with a graphical session (cosmic
  # here) - disable it until nixpkgs catches up.
  #
  # Workaround below: netbird-ui's own default -daemon-addr
  # (unix:///var/run/netbird/sock) already matches this module's default
  # client socket path, so the wrapper isn't buying us anything for the
  # default (unnamed) client - just install the unwrapped package directly
  # and use its own (already-valid) .desktop file for autostart. The daemon
  # socket is world read/write in this (non-hardened) config, so no group
  # membership is needed to reach it.
  services.netbird.ui.enable = false;
  environment.etc."xdg/autostart/netbird-ui.desktop".source =
    "${pkgs.netbird-ui}/share/applications/netbird.desktop";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "stormbreaker";

  # agenix's identity (/persist/ssh/ssh_host_ed25519_key, see _common) must be
  # readable during nixos-activation, which runs during the initrd->real-root
  # transition before ordinary (non-neededForBoot) filesystems mount - without
  # this, every age secret silently fails to decrypt on every cold boot.
  fileSystems."/persist".neededForBoot = true;

  networking.networkmanager.enable = true;

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
    netbird-ui
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
    vscodium
    wget
    zed-editor
    zola
  ];

  # 1Password
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "angelus" ];
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

  # power-profiles-daemon runtime-suspends the Synaptics fingerprint reader
  # (USB 06cb:*) after 2s idle; libfprint doesn't always wake it in time,
  # causing "No such device" / "device is still busy" errors from fprintd
  # and slow/unreliable scans (confirmed on mjolnir, same 06cb:00bd sensor
  # despite this being an X12 Detachable rather than a T490).
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
    inputs.lanzaboote.nixosModules.lanzaboote
    ./secrets
    ./boot.nix
    ./disko.nix
    #./hardware-configuration.nix
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
