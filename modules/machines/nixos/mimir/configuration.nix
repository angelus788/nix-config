{ pkgs
, config
, lib
, ...
}:
{
  boot.kernelModules = [
    "i915"
    "cp210x"
  ];
  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;
  boot.kernelParams = [
    "pcie_aspm=force"
    "consoleblank=60"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "mimir";
  };

  imports = [
    ../../../misc/agenix
    ./router
    ./filesystems
    ./secrets
    ./disko.nix
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
      homeassistant.enable = false;
      raspberrymatic.enable = false;
      uptime-kuma.enable = true;
      grafana.enable = true;
      prometheus = {
        enable = false;
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
    btrfs-progs
  ];
}
