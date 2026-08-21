{ pkgs, ... }:
let
  # Use pkgs.stdenv to avoid the "undefined variable" error on Darwin
  isLinux = pkgs.stdenv.hostPlatform.isLinux;

  # Every new Ghostty tab/window runs this. Plain `tmux new-session -A -s main`
  # would attach every client to the literal same session, and tmux gives all
  # clients on one session the same active window - so switching windows (or
  # running a fullscreen program) in one tab forces every other tab to show it
  # too. Instead: the first tab creates "main"; every later tab joins it as a
  # *grouped* session (shares main's windows/panes, but gets its own
  # independent current-window pointer, so tabs stop mirroring each other).
  # Joining the group alone isn't enough though: a bare grouped `new-session`
  # lands on window 1 by default, which is normally whatever the first tab is
  # already running (e.g. Claude Code) - so it still looked mirrored. Chaining
  # `new-window` makes each new tab create and switch to its own fresh window
  # instead of defaulting into window 1. Grouped sessions are marked
  # destroy-unattached so closing a tab cleans up its session instead of
  # leaving zombies (the window it created is left behind, harmless idle shell
  # - renumber-windows is already on so gaps don't linger); "main" itself is
  # left alone so it survives (and is restored by tmux-continuum/resurrect
  # across full quits).
  tmuxBin = "/run/current-system/sw/bin/tmux";
  tmuxAttachScript = pkgs.writeShellScript "ghostty-tmux-attach" ''
    if ${tmuxBin} has-session -t main 2>/dev/null; then
      exec ${tmuxBin} new-session -t main \; new-window \; set-option destroy-unattached on
    else
      exec ${tmuxBin} new-session -s main
    fi
  '';

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

      command = "${tmuxAttachScript}";

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
