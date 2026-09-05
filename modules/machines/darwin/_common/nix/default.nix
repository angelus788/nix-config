{ lib, config, ... }:
{
  nix = {
    gc = {
      automatic = true;
      # Without this, nix-collect-garbage runs with no arguments and only
      # removes fully-unreferenced paths - old generations keep almost
      # everything alive, so this barely reclaims any space. Matches the
      # retention already used on NixOS/standalone-HM hosts.
      options = "--delete-older-than 7d";
    };
    optimise = {
      automatic = true;
    };

    settings.experimental-features = lib.mkDefault [
      "nix-command"
      "flakes"
    ];

    settings.trusted-users = [
      "root"
      "angelus"
      "@wheel"
    ];
  };

  # nix-darwin has no equivalent of NixOS's nix.gc.persistent - the
  # generated LaunchDaemon only fires at its scheduled calendar time
  # (Sat 3:15am by default), with no catch-up if the machine was asleep or
  # off. For a laptop that's realistically never awake at that exact
  # moment, that means GC may go a very long time without ever actually
  # running. RunAtLoad makes it also fire whenever the job is (re)loaded -
  # every boot, and every darwin-switch - which for a daily-driver laptop
  # is a far more reliable trigger than the fixed weekly slot alone.
  #
  # ProgramArguments is fully overridden (not just RunAtLoad) to also fix a
  # separate, recurring problem: pre-built, upstream-codesigned .app
  # bundles (Ghostty, VSCodium, VS Code, Brave, Obsidian, Zed, Karabiner,
  # pinentry-mac all hit this) end up with some macOS-level protection
  # that makes fchmodat fail with "Operation not permitted", even for
  # root - not a chflags flag, not an ACL, not a blocking xattr beyond the
  # benign com.apple.macl tag ever found by inspection. nix-collect-garbage
  # aborts entirely on the first one it can't chmod, silently zeroing out
  # the whole run - so a single new orphaned app bundle from any package
  # update is enough to make GC free nothing until someone notices. Sweeping
  # xattrs/permissions on every .app under the store first (best-effort,
  # `; ` not `&&`, so this can't block the actual gc from running) makes
  # this self-healing instead of a silent, repeating failure.
  launchd.daemons.nix-gc.serviceConfig = {
    RunAtLoad = lib.mkForce true;
    ProgramArguments = lib.mkForce [
      "/bin/sh"
      "-c"
      ''
        /bin/wait4path /nix/store &&
        /usr/bin/find /nix/store -iname "*.app" -type d \
          -exec /usr/bin/xattr -cr {} \; \
          -exec /bin/chmod -R u+w {} \; \
          2>/dev/null ;
        exec ${config.nix.package}/bin/nix-collect-garbage ${config.nix.gc.options}
      ''
    ];
  };
}
