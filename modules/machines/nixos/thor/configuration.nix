{ config, pkgs, ... }:

{
  boot.loader.grub.enable = true;
  boot.loader.grub.useOSProber = true;

  networking.hostName = "thor"; # Define your hostname.
  networking.networkmanager.enable = true;
  # NetBird's DNS split-resolution (thor.thorsaga.net -> the wt0 overlay IP,
  # used by hermes-agent to bind) only works if something hands it control
  # over resolution; NetworkManager's own resolv.conf writer doesn't defer
  # to it, which otherwise leaves the hostname resolving to the public IP.
  networking.networkmanager.dns = "systemd-resolved";
  services.resolved.enable = true;

  # agenix's identity (/persist/ssh/ssh_host_ed25519_key, see _common) must be
  # readable during nixos-activation, which runs during the initrd->real-root
  # transition before ordinary (non-neededForBoot) filesystems mount - without
  # this, every age secret silently fails to decrypt on every cold boot.
  fileSystems."/persist".neededForBoot = true;

  services.duckdns = {
    enable = true;
    domainsFile = config.age.secrets.duckDNSDomain.path;
    tokenFile = config.age.secrets.duckDNSToken.path;
  };

  environment.systemPackages = with pkgs; [
    gnome-keyring
    claude-code
    pciutils
    glances
    hdparm
    hd-idle
    hddtemp
    just
    smartmontools
    cpufrequtils
    intel-gpu-tools
    powertop
    caddy
    wakeonlan
    wireguard-tools
    wget
  ];

  imports = [
    # Include the results of the hardware scan.
    #../../../misc/avgtechguy.com
    ./hardware-configuration.nix
    ./disko.nix
    ../../../apps/netbird
    ./secrets
    ./homelab.nix
  ];

  home-manager.users.angelus.myHomeDots.enableGui = false;

}
