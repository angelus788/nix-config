{ pkgs
, inputs
, config
, lib
, ...
}:

{
  home.username = lib.mkForce "deck";
  home.homeDirectory = lib.mkForce "/home/deck";

  # ---------------------------------------------------------------------------
  # SteamOS / Handheld Packages & Utilities
  # ---------------------------------------------------------------------------
  home.packages = with pkgs; [
    # Modern CLI defaults matching your workflow
    ripgrep
    fd
    eza
    btop
    jq
    tmux

    # Sync & Data Transfer Tools
    syncthing

    # Useful Desktop / Gaming utilities for SteamOS Desktop Mode
    protonup-qt
  ];

  # ---------------------------------------------------------------------------
  # Shell & Terminal Integrations
  # ---------------------------------------------------------------------------
  programs.bash = {
    enable = true;
    initExtra = ''
      # Ensure Nix user profile binaries are in PATH
      export PATH="$HOME/.nix-profile/bin:$PATH"

      # Auto-exec into Zsh for interactive sessions if Zsh exists
      if [ -t 1 ] && [ -z "$INTELLIJ_ENVIRONMENT_READER" ] && command -v zsh >/dev/null 2>&1; then
        export SHELL="$(command -v zsh)"
        exec zsh
      fi
    '';
  };

  imports = [
    ../../../misc/syncthing-hm
    ../../../misc/syncthing-settings
    ../../../misc/netbird-hm
    ../../../misc/agenix
    ./secrets.nix
  ];
}
