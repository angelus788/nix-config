{ pkgs, ... }:
{
  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty-bin;
    settings = {
      theme = "nord";
      font-size = 16;
      font-family = "Comic Code Ligatures";
      command = "/etc/profiles/per-user/angelus/bin/tmux";
      adjust-cell-height = "50%";
      font-thicken = true;
      font-thicken-strength = 120;
    };
  };
}
