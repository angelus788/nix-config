{ pkgs, inputs, config, ... }:

{
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
    syncthing # Great for syncing offline game saves across PC & Steam Deck

    # Useful Desktop / Gaming utilities for SteamOS Desktop Mode
    protonup-qt # Easily download GE-Proton / Wine versions for Steam
    flatpak # Interop tool if you run local Flatpak builds
  ];

  # ---------------------------------------------------------------------------
  # Shell & Terminal Integrations
  # ---------------------------------------------------------------------------
  # Automatically load Nix environment binaries into PATH for interactive shells
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

  syncthingSettings = {
    guiPassword = "$2b$05$Xl3P7nFnclVkHhkbRJjsAeOwsIP3O.2mvdQGm3jKUAwqWH72CDagC";
    folders = {
      d2r-offline-saves.path = "/home/angelus/d2r-offline-saves";
      Documents.path = "/home/angelus/Documents";
      Homework.path = "/home/angelus/Homework";
      remarkable_sync.path = "/home/angelus/remarkable_sync";
      pdf2remarkable.path = "/home/angelus/pdf2remarkable";
    };
  };

  imports = [
    ../../../misc/syncthing
    ../../../misc/tailscale
    ../../../misc/agenix
  ];
}
