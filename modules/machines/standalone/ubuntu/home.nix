{ pkgs
, inputs
, config
, ...
}:

{
  imports = [
    ../../../misc/netbird-hm
    ../../../misc/syncthing-hm # Uses the Home Manager refactored Syncthing module
    ../../../misc/syncthing-settings
    ../../../misc/agenix
    ./secrets.nix
  ];

  # ---------------------------------------------------------------------------
  # Ubuntu Server Packages & Utilities
  # ---------------------------------------------------------------------------
  home.packages = with pkgs; [
    # Modern CLI & Diagnostics Tooling
    ripgrep
    fd
    eza
    btop
    htop
    jq
    tmux
    git
    curl
    wget

    # Sync & Data Utilities
    syncthing
    rsync
  ];

  # ---------------------------------------------------------------------------
  # Shell & Terminal Integrations
  # ---------------------------------------------------------------------------
  # Ensure Nix binaries are prioritized and auto-exec into Zsh for interactive shells
  programs.bash = {
    enable = true;
    initExtra = ''
      # Ensure Nix user profile binaries are in PATH on Ubuntu
      export PATH="$HOME/.nix-profile/bin:$PATH"

      # Auto-exec into Zsh for interactive sessions if Zsh exists
      if [ -t 1 ] && [ -z "$INTELLIJ_ENVIRONMENT_READER" ] && command -v zsh >/dev/null 2>&1; then
        export SHELL="$(command -v zsh)"
        exec zsh
      fi
    '';
  };


  # ---------------------------------------------------------------------------
  # User-Level Systemd Services (Ubuntu headless)
  # ---------------------------------------------------------------------------
  # Keeps background tools like tmux sessions or user systemd units alive
  # even when you log out of SSH (optional, but very helpful on headless servers)
  #
  # Note: To enable linger on Ubuntu, run once via SSH: loginctl enable-linger $USER
}
