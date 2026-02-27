{ pkgs, ... }:

{
  home.packages = [
    pkgs.bitwarden-desktop
    pkgs.bitwarden-cli
  ];

  # This sets the environment variable so SSH knows to talk to Bitwarden
  home.sessionVariables = {
    SSH_AUTH_SOCK = "$HOME/.bitwarden-ssh-agent.sock";
  };
}
