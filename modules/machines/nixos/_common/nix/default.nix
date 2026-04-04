{ lib, ... }:
{
  nix = {
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
      persistent = true;
    };
    optimise = {
      automatic = true;
      dates = [ "daily" ];
    };

    settings.auto-optimise-store = true;

    settings.experimental-features = lib.mkDefault [
      "nix-command"
      "flakes"
    ];
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };
}
