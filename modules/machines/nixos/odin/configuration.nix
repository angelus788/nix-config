{ config
, lib
, pkgs
, ...
}:
let
  hl = config.homelab;
  lan = hl.networks.local.lan;
  odinIPAddress = lan.reservations.odin.Address;
  hardDrives = [
    "/dev/disk/by-label/Data1"
    "/dev/disk/by-label/Data2"
    "/dev/disk/by-label/Data3"
    "/dev/disk/by-label/Data4"
    "/dev/disk/by-label/Parity1"
  ];
in
{
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
  boot.zfs.extraPools = [ "cache" ]; #might need to remove
  boot.zfs.forceImportRoot = true;
  boot.kernelParams = [
    "pcie_aspm=force"
    "consoleblank=60"
  ];

  zfs-root = {
    boot = {
      devNodes = "/dev/disk/by-id/";
      bootDevices = [ "ata-CT500MX500SSD1_1947E228A4C0" ];
      partitionScheme = {
        biosBoot = "-part1"; # Not used on UEFI, but prevents errors
        efiBoot = "-part1"; # This is your vfat partition
        bootPool = "-part2"; # This is your bpool
        rootPool = "-part3"; # This is your rpool
      };
      immutable = true;
      removableEfi = true;
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod"
        "sr_mod"
      ];
    };
  };

  systemd.network = {
    enable = true;
    networks = {
      "10-lan1" = {
        matchConfig.Name = "lan1";
        networkConfig = {
          DHCP = true;
          Address = odinIPAddress;
          IPv6AcceptRA = true;
          LinkLocalAddressing = "ipv6";
        };
        dhcpV4Config = {
          UseHostname = false;
          UseDNS = true;
          UseNTP = true;
          UseSIP = false;
          ClientIdentifier = "mac";
        };
        ipv6AcceptRAConfig = {
          UseDNS = true;
          DHCPv6Client = true;
        };
        dhcpV6Config = {
          WithoutRA = "solicit";
          UseDelegatedPrefix = true;
          UseHostname = false;
          UseDNS = true;
          UseNTP = false;
        };
        linkConfig.RequiredForOnline = "routable";
      };
    };
  };
  networking = {
    useDHCP = false;
    hostName = "odin";
    hostId = "437fdd78";
    firewall = {
      enable = true;
      allowPing = true;
      trustedInterfaces = [
        "lan1"
        "tailscale0"
      ];
    };
  };

  imports = [
    ../../../misc/tailscale
    ../../../misc/zfs-root
    ../../../misc/agenix
    ./filesystems
    #./backup
    ./homelab
    ./secrets
    ./disko.nix
    ./boot.nix
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
        pwmPaths = [ "/sys/class/hwmon/hwmon2/device/pwm2:50:50" ];
        extraArgs = [
          "-i 30sec"
        ];
      };
    };
  };

  virtualisation.docker.storageDriver = "overlay2";

  system.autoUpgrade.enable = true;

  #services.withings2intervals = {
  #  enable = true;
  #  configFile = config.age.secrets.withings2intervals.path;
  #  authCodeFile = config.age.secrets.withings2intervals_authcode.path;
  #};

  #services.mover = {
  #  enable = true;
  #  cacheArray = hl.mounts.fast;
  #  backingArray = hl.mounts.slow;
  #  user = hl.user;
  #  group = hl.group;
  #  percentageFree = 60;
  #  excludedPaths = [
  #    "Media/Music"
  #    "Media/Photos"
  #    "YoutubeCurrent"
  #    "Downloads.tmp"
  #    "Media/Kiwix"
  #    "Documents"
  #    "TimeMachine"
  #    ".DS_Store"
  #    ".cache"
  #  ];
  #};

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
  ];

  #tg-notify = {
  #  enable = true;
  #  credentialsFile = config.age.secrets.tgNotifyCredentials.path;
  #};

  #services.adiosBot = {
  #  enable = true;
  #  botTokenFile = config.age.secrets.adiosBotToken.path;
  #};
}
