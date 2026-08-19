{ config, pkgs, ... }:

{
  boot.loader.grub.enable = true;
  boot.loader.grub.useOSProber = true;

  networking.hostName = "thor"; # Define your hostname.
  networking.networkmanager.enable = true;

  services.duckdns = {
    enable = true;
    domainsFile = config.age.secrets.duckDNSDomain.path;
    tokenFile = config.age.secrets.duckDNSToken.path;
  };

  environment.systemPackages = with pkgs; [
    gnome-keyring
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
    #../../../apps/netbird
    ./hardware-configuration.nix
    ./disko.nix
    ../../../apps/tailscale
    ./secrets
  ];

  home-manager.users.angelus.myHomeDots.enableGui = false;

}
