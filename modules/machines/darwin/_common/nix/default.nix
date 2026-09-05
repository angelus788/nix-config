{ lib, ... }:
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
  launchd.daemons.nix-gc.serviceConfig.RunAtLoad = lib.mkForce true;
}
