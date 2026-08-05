{ lib, pkgs, ... }:
{
  nix = {
    gc = {
      automatic = true;
      frequency = "daily"; # HM uses 'frequency' instead of 'dates'
      options = "--delete-older-than 7d";
      # Note: 'persistent' is a systemd system option, not supported in HM
    };

    # Generates user-level ~/.config/nix/nix.conf
    settings = {
      experimental-features = lib.mkDefault [
        "nix-command"
        "flakes"
      ];
    };
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
      permittedInsecurePackages = [
        "electron-39.8.10"
        "ventoy-1.1.12"
      ];
    };
  };
}
