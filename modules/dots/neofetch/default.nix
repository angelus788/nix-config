{ pkgs, ... }:
{
  home.packages = with pkgs; [
    fastfetch
  ];
  xdg.configFile = {
    "neofetch/config.conf" = {
      source = ./config.conf;
    };
  };
}
