{ config, lib, pkgs, ... }:

let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  guiEnabled = config.myHomeDots.enableGui or false;
in
{
  # ------------------------------------------------------------------
  # ALWAYS APPLIES (All hosts: Darwin, Linux, Headless, GUI)
  # ------------------------------------------------------------------
  home.sessionVariables = {
    SSH_AUTH_SOCK = "$HOME/.bitwarden-ssh-agent.sock";
  };

  # ------------------------------------------------------------------
  # PACKAGES (Platform / GUI Conditional)
  # ------------------------------------------------------------------
  home.packages = with pkgs; [
    # Always install CLI everywhere
    bitwarden-cli
  ] 
  # Only install desktop app from Nixpkgs on Linux GUI hosts
  ++ lib.optionals (isLinux && guiEnabled) [
    bitwarden-desktop
  ];
}