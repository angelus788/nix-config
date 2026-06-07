{
  config,
  lib,
  pkgs,
  ...
}:
let
  hl = config.homelab;
  hardDrives = [
    "/dev/disk/by-label/data1"
    "/dev/disk/by-label/data2"
    "/dev/disk/by-label/data3"
    "/dev/disk/by-label/data4"
    "/dev/disk/by-label/parity1"
  ];
in
{
  # 1. Disable GRUB
  boot.loader.grub.enable = false;

  # 2. Enable systemd-boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # 3. Double-check the ZFS kill-switch
  networking.hostId = lib.mkForce null;

  networking.hosts = {
    "127.0.0.1" = [ "login.internalnetwork.party" ];
  };

  #services.prometheus.exporters = {
  #  shellyplug = {
  ##    enable = true;
  #   targets = [
  #     "192.168.32.4"
  #   ];
  # };
  # systemd = {
  #   enable = true;
  #   openFirewall = false;
  # };
  #node = {
  #  enable = true;
  #  openFirewall = false;
  #};
  #smartctl = {
  #  enable = true;
  #  openFirewall = false;
  #};
  #};

  services.udev.extraRules = ''
    SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="68:05:ca:39:92:d8", ATTR{type}=="1", NAME="lan0"
    SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="68:05:ca:39:92:d9", ATTR{type}=="1", NAME="lan1"
  '';
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
  hardware = {
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = true;
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-vaapi-driver
        libva-vdpau-driver
        intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
        vpl-gpu-rt # QSV on 11th gen or newer
      ];
    };
  };

  boot.kernelModules = [ "nct6775" ];
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usb_storage"
    "sd_mod"
    "xhci_pci"
    "ahci"
    "usbhid"
    "sr_mod"
  ];
  boot.supportedFilesystems = lib.mkForce [
    "btrfs"
    "xfs"
    "vfat"
  ];
  boot.initrd.kernelModules = [ "btrfs" ];

  networking = {
    useDHCP = false;
    hostName = "odin";
    interfaces.enp1s0.useDHCP = true;
    firewall = {
      enable = true;
      allowPing = true;
      trustedInterfaces = [
        "lan1"
        "tailscale0"
        "enp1s0"
      ];
    };
  };

  imports = [
    #../../../misc/avgtechguy.com
    ../../../misc/syncthing
    ../../../misc/tailscale
    ../../../misc/agenix
    ./filesystems
    #./backup
    ./homelab
    ./secrets
    ./disko.nix
  ];

  services.duckdns = {
    enable = true;
    domainsFile = config.age.secrets.duckDNSDomain.path;
    tokenFile = config.age.secrets.duckDNSToken.path;
  };

  systemd.services.hd-idle = {
    description = "External HD spin down daemon";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart =
        let
          idleTime = toString 900;
          hardDriveParameter = lib.strings.concatMapStringsSep " " (x: "-a ${x} -i ${idleTime}") hardDrives;
        in
        "${pkgs.hd-idle}/bin/hd-idle -i 0 ${hardDriveParameter}";
    };
  };

services.hddfancontrol = {
    enable = true;
    settings = {
      harddrives = {
        disks = hardDrives;
        pwmPaths = [ "/run/hddfancontrol-harddrives/pwm2:50:50" ];
        extraArgs = [
          "-i 30sec"
        ];
      };
    };
  };

  systemd.services.hddfancontrol-harddrives = {
    # preStart runs as a shell script right before ExecStart
    preStart = ''
      mkdir -p /run/hddfancontrol-harddrives
      rm -f /run/hddfancontrol-harddrives/pwm2

      for dev in /sys/class/hwmon/hwmon*; do
        if [ "$(cat "$dev/name")" = "nct6798" ]; then
          ln -s "$dev/pwm2" /run/hddfancontrol-harddrives/pwm2
          exit 0
        fi
      done

      echo "Error: nct6798 hardware monitor not found!" >&2
      exit 1
    '';
    
    # Ensure systemd sets up the runtime directory permissions safely
    serviceConfig.RuntimeDirectory = "hddfancontrol-harddrives";
  };

  virtualisation.docker.storageDriver = "overlay2";

  system.autoUpgrade.enable = true;

  #services.withings2intervals = {
  #  enable = true;
  #  configFile = config.age.secrets.withings2intervals.path;
  #  authCodeFile = config.age.secrets.withings2intervals_authcode.path;
  #};

  services.mover = {
    enable = true;
    cacheArray = hl.mounts.fast;
    backingArray = hl.mounts.slow;
    user = hl.user;
    group = hl.group;
    percentageFree = 60;
    excludedPaths = [
      "Media/Music"
      "Media/Photos"
      "YoutubeCurrent"
      "Downloads.tmp"
      "Media/Kiwix"
      "Documents"
      "TimeMachine"
      ".DS_Store"
      ".cache"
    ];
  };

  services.autoaspm.enable = true;
  powerManagement.powertop.enable = true;

  environment.systemPackages = with pkgs; [
    pciutils
    glances
    hdparm
    hd-idle
    hddtemp
    smartmontools
    cpufrequtils
    intel-gpu-tools
    powertop
    caddy
  ];
home-manager.users.angelus.myHomeDots.enableGui = false;

  tg-notify = {
    enable = true;
    credentialsFile = config.age.secrets.tgNotifyCredentials.path;
  };

  #services.adiosBot = {
  #  enable = true;
  #  botTokenFile = config.age.secrets.adiosBotToken.path;
  #};

  syncthingSettings = {
    guiPassword = "$2b$05$Xl3P7nFnclVkHhkbRJjsAeOwsIP3O.2mvdQGm3jKUAwqWH72CDagC";
    folders = {
      d2r-offline-saves.path = "/home/angelus/d2r-offline-saves";
      Documents.path = "/home/angelus/Documents";
      Homework.path = "/home/angelus/Homework";
      remarkable_sync.path = "/home/angelus/remarkable_sync";
      pdf2remarkable.path = "/home/angelus/pdf2remarkable";
    };
  };
}
