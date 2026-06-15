{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  iot = config.homelab.networks.local.iot.reservations;
  #  tvIpAddress = iot.lgtv.Address;
  #  tvMacAddress = iot.lgtv.MACAddress;
  tvIpAddress = iot.samsungtv.Address;
  tvMacAddress = iot.samsungtv.MACAddress;
in
{

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.extraModprobeConfig = ''
    options bluetooth disable_ertm=1
  '';

  imports = [
    #./hardware-configuration.nix
    ./secrets
    ../../../misc/ryzen-undervolting
    ../../../misc/samsung-tv
    ../../../misc/syncthing
    ../../../apps/tailscale
    #../../../misc/lgtv
    inputs.jovian.nixosModules.default
    ./lact.nix
    ./boot.nix
    ./no-rgb.nix
    ./disko.nix
  ];

  environment.systemPackages = [
    pkgs.firefox-bin
    pkgs.bitwarden-cli
    pkgs.bitwarden-desktop
    #pkgs.lutris #enable later on
    pkgs.s-tui
    pkgs.stress
  ];

  # fileSystems."/" = {
  #   device = "/dev/disk/by-id/nvme-CT1000P1SSD8_202629273359_1-part2";
  #   fsType = "ext4";
  # };
  # fileSystems."/boot" = {
  #   device = "/dev/disk/by-id/nvme-CT1000P1SSD8_202629273359_1-part1";
  #   fsType = "vfat";
  # };

  hardware = {
    bluetooth.enable = lib.mkForce false;
    bluetooth.powerOnBoot = false;
    enableRedistributableFirmware = true;
    xpadneo.enable = true;
    cpu.amd = {
      updateMicrocode = true;
      ryzen-smu.enable = true;
    };
    xone.enable = true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  services = {
    openssh.enable = true;
    desktopManager.plasma6.enable = true;
    #lgtv = {
    #  enable = true;
    #  ipAddress = tvIpAddress;
    #  macAddress = tvMacAddress;
    #  user = "angelus";
    #  group = "angelus";
    #};
    samsungtv = {
      enable = false;
      ipAddress = tvIpAddress;
      macAddress = tvMacAddress;
      hdmiInput = "HDMI1";
      user = "angelus";
      group = "angelus";
    };
    ryzen-undervolting = {
      enable = true;
      offset = -25;
    };
  };

  networking = {
    networkmanager.enable = true;
    hostName = "mayra";
    hostId = "899635ed";
    interfaces.enp6s0.wakeOnLan = {
      #enp4s0
      enable = true;
    };
  };

  jovian = {
    hardware = {
      has.amd.gpu = true;
      amd.gpu.enableBacklightControl = false;
    };
    steam = {
      updater.splash = "vendor";
      enable = true;
      autoStart = true;
      user = "angelus";
      desktopSession = "plasma";
    };
    steamos = {
      useSteamOSConfig = true;
    };
  };
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true; # Necessary for KMS display capture
    openFirewall = true; # Opens the default ports: 47984-48010
  };

    syncthingSettings = {
    guiPassword = "$2b$05$Xl3P7nFnclVkHhkbRJjsAeOwsIP3O.2mvdQGm3jKUAwqWH72CDagC";
    folders = {
      d2r-offline-saves.path = "/home/angelus/.local/share/Steam/steamapps/compatdata/2536520/pfx/drive_c/users/steamuser/Saved Games/Diablo II Resurrected";
      Documents.path = "/home/angelus/Documents";
      Homework.path = "/home/angelus/Homework";
      remarkable_sync.path = "/home/angelus/remarkable_sync";
      pdf2remarkable.path = "/home/angelus/pdf2remarkable";
    };
  };

  home-manager.users.angelus.myHomeDots.enableGui = true;
}
