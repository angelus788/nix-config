{ lib, ... }:
{
  nix = {
    gc = {
      automatic = true;
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
}
