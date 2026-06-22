{  config, lib, ... }:
let
  home = {
    username = "angelus";
    homeDirectory = "/home/angelus";
    stateVersion = "25.11";
  };
in
{



  imports = [
    ./gitconfig.nix
      ../../dots/neofetch/default.nix
      ../../dots/ssh/default.nix
      ../../dots/zsh/default.nix
      ../../dots/bitwarden/default.nix
      ../../dots/firefox/default.nix
      ../../dots/ghostty/default.nix
      #../../dots/librewolf/default.nix
      ../../dots/tssystray/default.nix
      ../../dots/variety/default.nix
      ../../dots/vscodium/default.nix
      #g../../dots/wpaperd/default.nix
      ../../dots/zed/default.nix
  ];

    options.myHomeDots = {
        enableGui = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable GUI-specific dotfiles like desktop apps and window utilities.";
        };
        enableCore = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable core/headless terminal dotfiles needed everywhere.";
        };
      };

  config = {
  #  nixpkgs = {
  #    overlays = [ ];
  #    config = {
  #      allowUnfree = true;
  #      allowUnfreePredicate = (_: true);
  #      permittedInsecurePackages = [ ##COMEBACKTOTHIS##
  #              "electron-39.8.10"
  #      ];
        
  #  };
  #};

  home = home;

  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.home-manager.enable = true;

  systemd.user.startServices = "sd-switch";
  };
}
