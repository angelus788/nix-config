{ config, pkgs, ... }:
{

  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  
  services.xserver.enable = true;

}