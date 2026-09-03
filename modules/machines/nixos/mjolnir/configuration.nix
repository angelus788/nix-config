{ pkgs, inputs, lib, config, ... }:

{

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

  # Fronts the Syncthing GUI (loopback:8384, see modules/misc/syncthing)
  # with a real Let's Encrypt cert so it's reachable without :8384 - same
  # pattern as odin's kvm.thorsaga.net / odin-syncthing.thorsaga.net (see
  # modules/machines/nixos/odin/homelab/default.nix). Requires an Extra DNS
  # Label on this host's own NetBird peer (mjolnir-syncthing) - see
  # [[homelab_netbird_extra_dns_labels]] memory for why that needs a full
  # peer remove+re-register, not just `netbird up --extra-dns-labels`.
  security.acme = {
    acceptTerms = true;
    defaults.email = "avgtechguy@mailbox.org";
    certs."thorsaga.net" = {
      reloadServices = [ "caddy.service" ];
      domain = "thorsaga.net";
      extraDomainNames = [ "*.thorsaga.net" ];
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      dnsPropagationCheck = true;
      group = config.services.caddy.group;
      environmentFile = config.age.secrets.cloudflareDnsApiCredentials.path;
    };
  };
  services.caddy = {
    enable = true;
    virtualHosts."mjolnir-syncthing.thorsaga.net" = {
      useACMEHost = "thorsaga.net";
      extraConfig = ''
        reverse_proxy 127.0.0.1:8384
      '';
    };
  };
  networking.firewall.interfaces.${config.services.netbird.clients.default.interface}.allowedTCPPorts = [ 443 ];

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
    pkgs.netbird-ui
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
