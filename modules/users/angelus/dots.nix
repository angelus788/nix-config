{ ... }:
let
  home = {
    username = "angelus";
    homeDirectory = "/home/angelus";
    stateVersion = "25.11";
  };
in
{

  nixpkgs = {
    overlays = [ ];
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };

  home = home;

  imports = [
    ../../dots/bitwarden/default.nix
    ../../dots/firefox/default.nix
    ../../dots/zsh/default.nix
    #../../dots/neofetch/default.nix
    ../../dots/vscodium/default.nix
    ../../dots/zed/default.nix
    ../../dots/ssh/default.nix
    ../../dots/tssystray/default.nix
    ../../dots/wpaperd/default.nix
    ./gitconfig.nix
  ];

  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.home-manager.enable = true;

  systemd.user.startServices = "sd-switch";
}
