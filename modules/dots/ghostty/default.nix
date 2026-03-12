{ pkgs, stdenv, ... }:
let
  # Check if we are on Linux (Mjolnir)
  isLinux = stdenv.isLinux;
in
{
  programs.ghostty = {
    enable = true;
    # On Linux use the GTK package; on macOS use ghostty-bin
    package = if isLinux then pkgs.ghostty else pkgs.ghostty-bin;

    settings = {
      theme = "nord";
      font-size = 16;
      font-family = "Comic Code Ligatures";

      # Use the direct store path for reliability on NixOS
      command = "${pkgs.tmux}/bin/tmux";

      adjust-cell-height = "50%";

      # --- PLATFORM SPECIFIC ---
      # Only apply these on macOS
      font-thicken = if isLinux then false else true;
      font-thicken-strength = if isLinux then null else 120;
    };
  };
}











#{ pkgs, ... }:
#{
#  programs.ghostty = {
#    enable = true;
#    package = pkgs.ghostty-bin;
#    settings = {
#      theme = "nord";
#      font-size = 16;
#      font-family = "Comic Code Ligatures";
#      command = "/run/current-system/sw/bin/tmux";
#command = "${pkgs.zsh}/bin/zsh -c ${pkgs.tmux}/bin/tmux";
#command = "sleep 5 && /run/current-system/sw/bin/tmux";
#    adjust-cell-height = "50%";
#      font-thicken = true;
#      font-thicken-strength = 120;
#    };
#  };
#}
