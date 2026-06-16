{ config, pkgs, ... }:
{

  # SDDM Display Manager
    services.displayManager.sddm = {
    enable = true;
    theme = "breeze";
    wayland.enable = true;
    enableHidpi = true;
    settings = {
      Autologin = {
        Session = "plasma.desktop";
        User = "angelus";
      };
    };
  };

  # Plasma 6
  services.desktopManager.plasma6.enable = true;

  # Exclude certain default applications from being installed
  #environment.plasma6.excludePackages = with pkgs; [ kdePackages.<package> ]; 

}