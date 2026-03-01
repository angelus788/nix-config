{
  pkgs,
  config,
  lib,
  ...
}:
{
  boot.kernelModules = [
    "i915"
    "cp210x"
  ];
  hardware.cpu.ryzen.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;
  boot.zfs.forceImportRoot = true;
  boot.kernelParams = [
    "pcie_aspm=force"
    "consoleblank=60"
  ];
  networking = {
    hostName = "mimir";
    hostId = "73cd46a7";
  };

  zfs-root = {
    boot = {
      bootDevices = [
        "nvme-CT500P1SSD8_1937E21ED6C8"
        "ata-2.5__SATA_SSD_3MG2-P_20180326AA1322000496"
      ];
      immutable = false;
      availableKernelModules = [
        "uhci_hcd"
        "ehci_pci"
        "ahci"
        "sd_mod"
        "sr_mod"
      ];
      removableEfi = true;
    };
  };

  imports = [
    ../../../misc/zfs-root
    ../../../misc/agenix
    ./router
    ./filesystems
    ./secrets
  ];

  virtualisation.docker.storageDriver = "overlay2";

  homelab = {
    enable = true;
    cloudflare.dnsCredentialsFile = config.age.secrets.cloudflareDnsApiCredentials.path;
    baseDomain = "internalnetwork.party";
    timeZone = "America/New_York";
    mounts = {
      config = "/persist/opt/services";
    };
    services = {
      enable = true;
      homeassistant.enable = true;
      raspberrymatic.enable = true;
      uptime-kuma.enable = true;
      grafana.enable = true;
      prometheus = {
        enable = true;
        scrapeTargets = lib.lists.forEach [ "smartctl" "node" "systemd" "shellyplug" ] (exporter: {
          job_name = exporter;
          static_configs = [
            {
              targets = (
                lib.lists.forEach [ "localhost" "heimdall" "odin" ] (
                  target: "${target}:${toString config.services.prometheus.exporters.${exporter}.port}"
                )
              );
            }
          ];
        });
      };
    };
  };
  services.caddy.globalConfig = ''
    default_bind ${config.homelab.networks.local.lan.cidr.v4}
  '';
  environment.systemPackages = with pkgs; [
    pciutils
    smartmontools
    powertop
    cpufrequtils
    gnumake
    gcc
    dig.dnsutils
  ];
}
