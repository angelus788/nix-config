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

  # agenix's identity (/persist/ssh/ssh_host_ed25519_key, see _common) must be
  # readable during nixos-activation, which runs during the initrd->real-root
  # transition before ordinary (non-neededForBoot) filesystems mount - without
  # this, every age secret silently fails to decrypt on every cold boot.
  fileSystems."/persist".neededForBoot = true;

  imports = [
    ../../../misc/agenix
    ./router
    ./filesystems
    ./secrets
    ./disko.nix
    ../../../apps/tailscale
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
      grafana.enable = false;
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
