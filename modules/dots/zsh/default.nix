{
  pkgs,
  config,
  inputs,
  lib,
  osConfig ? { },
  ...
}:
let
  # Safely detect hostname across NixOS and nix-darwin / Home Manager
  hostName = config.networking.hostName or osConfig.networking.hostName or "";

  # Target hosts that should decrypt and use Bitwarden credentials
  isTargetHost = builtins.elem hostName [
    "tyr"
    "mjolnir"
    "stormbreaker"
  ];
in
{
  home.packages = with pkgs; [ grc ];

  # 1. Load persistent API credentials for target hosts
  age.secrets = lib.mkIf isTargetHost {
    bwCredentials.file = "${inputs.secrets}/bwCredentials.age";
  };

  programs = {
    fzf = {
      enable = true;
      enableZshIntegration = true;
      colors = {
        fg = "#D8DEE9";
        bg = "#2E3440";
        hl = "#A3BE8C";
        "fg+" = "#D8DEE9";
        "bg+" = "#434C5E";
        "hl+" = "#A3BE8C";
        pointer = "#BF616A";
        info = "#4C566A";
        spinner = "#4C566A";
        header = "#4C566A";
        prompt = "#81A1C1";
        marker = "#EBCB8B";
      };
    };

    starship = {
      enable = true;
      enableZshIntegration = true;
      settings = pkgs.lib.importTOML ../starship/starship.toml;
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [ "--cmd cd" ];
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
    };

    zsh = {
      enable = true;
      enableCompletion = false;
      zplug = {
        enable = true;
        plugins = [
          { name = "zsh-users/zsh-autosuggestions"; }
          { name = "zsh-users/zsh-syntax-highlighting"; }
          { name = "zsh-users/zsh-completions"; }
          { name = "zsh-users/zsh-history-substring-search"; }
          { name = "unixorn/warhol.plugin.zsh"; }
        ];
      };

      shellAliases = {
        la = "ls --color -lha";
        df = "df -h";
        du = "du -ch";
        ipp = "curl ipinfo.io/ip";
        yh = "yt-dlp --continue --no-check-certificate --format=bestvideo+bestaudio --exec='ffmpeg -i {} -c:a copy -c:v copy {}.mkv && rm {}'";
        yd = "yt-dlp --continue --no-check-certificate --format=bestvideo+bestaudio --exec='ffmpeg -i {} -c:v prores_ks -profile:v 1 -vf fps=25/1 -pix_fmt yuv422p -c:a pcm_s16le {}.mov && rm {}'";
        ya = "yt-dlp --continue --no-check-certificate --format=bestaudio -x --audio-format wav";
        aspm = "sudo lspci -vv | awk '/ASPM/{print $0}' RS= | grep --color -P '(^[a-z0-9:.]+|ASPM )'";
        mkdir = "mkdir -p";
        deploy-nix = "f() { if [[ $(find . -mmin -60 -type f -name flake.lock | wc -c) -eq 0 ]]; then nix flake update; fi && deploy .#$1 --remote-build -s --auto-rollback false && rsync -ax --delete ./ $1:/etc/nixos/ };f";
      };

      initContent = ''
        # Cycle back in the suggestions menu using Shift+Tab
        bindkey '^[[Z' reverse-menu-complete
        bindkey '^B' autosuggest-toggle

        # Make Ctrl+W remove one path segment instead of the whole path
        WORDCHARS=''${WORDCHARS/\/}

        # Highlight the selected suggestion
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
        zstyle ':completion:*' menu yes=long select

        # macOS specific environment variables & paths
        ${
          if (pkgs.stdenv.hostPlatform.system == "aarch64-darwin") then
            ''
              path=("$HOME/.nix-profile/bin" "/run/wrappers/bin" "/etc/profiles/per-user/$USER/bin" "/nix/var/nix/profiles/default/bin" "/run/current-system/sw/bin" "/opt/homebrew/bin" $path)
              export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"
              alias lsblk="diskutil list"
              ulimit -n 2048
            ''
          else
            ""
        }

        # Auto-login and unlock Bitwarden if secret exists on this node
        ${lib.optionalString (config.age.secrets ? bwCredentials) ''
          if [ -f "${config.age.secrets.bwCredentials.path}" ]; then
            # Automatically export all variables loaded from the secret file
            set -a
            source "${config.age.secrets.bwCredentials.path}"
            set +a

            if command -v bw &> /dev/null; then
              if [ "$(bw status | ${pkgs.jq}/bin/jq -r '.status' 2>/dev/null)" = "unauthenticated" ]; then
                bw login --apikey > /dev/null 2>&1
              fi
              if [ "$(bw status | ${pkgs.jq}/bin/jq -r '.status' 2>/dev/null)" = "locked" ] && [ -n "$BW_PASSWORD" ]; then
                export BW_SESSION=$(bw unlock "$BW_PASSWORD" --raw 2>/dev/null)
              fi
            fi
          fi
        ''}

        export EDITOR=nvim || export EDITOR=vim
        export LANG=en_US.UTF-8
        export LC_CTYPE=en_US.UTF-8
        export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

        source $ZPLUG_HOME/repos/unixorn/warhol.plugin.zsh/warhol.plugin.zsh
        bindkey '^[[A' history-substring-search-up
        bindkey '^[[B' history-substring-search-down

        if command -v motd &> /dev/null; then
          motd
        fi
        bindkey -e

        if [[ "$TERM_PROGRAM" == "ghostty" ]]; then
          export TERM=xterm-256color
        fi
      '';
    };
  };
}
