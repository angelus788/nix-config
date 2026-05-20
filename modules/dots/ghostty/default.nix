{ pkgs, ... }:
let
  # Use pkgs.stdenv to avoid the "undefined variable" error on Darwin
  isLinux = pkgs.stdenv.isLinux;
in
{
  programs.ghostty = {
    enable = true;
    # Use the appropriate package for each OS
    package = if isLinux then pkgs.ghostty else pkgs.ghostty-bin;

    settings = {
      theme = "Nord";
      font-size = 16;
      font-family = "Comic Code Ligatures";

      # Since '/run/current-system/sw/bin/tmux' worked via CLI,
      # we use it here.
      command = "/run/current-system/sw/bin/tmux";

      adjust-cell-height = "50%";
    }
    # This merge operator (//) safely adds macOS-only settings
    # without breaking the Linux config.
    // (
      if isLinux then
        { }
      else
        {
          font-thicken = true;
          font-thicken-strength = 120;
        }
    );
  };
}
