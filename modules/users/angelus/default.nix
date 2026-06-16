{
  pkgs,
  ...
}:
{
  nix.settings.trusted-users = [
    "angelus"
    "root"
  ];

  users = {
    # 1. DEFINE THE USERS
    users = {
      angelus = {
        shell = pkgs.zsh;
        uid = 1000;
        isNormalUser = true;
        extraGroups = [
          "adbusers"
          "wheel"
          "users"
          "video"
          "podman"
          "input"
          "networkmanager"
          "share"
        ];
        group = "angelus";
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII07ukuUm57yQYo2YL8GSLtPU8z9Q0NdU28d49wdoxbw"
        ];
      };

      acme = {
        isSystemUser = true;
        group = "acme";
        extraGroups = [ "caddy" ]; # The permission bridge
      };
    };

    # 2. DEFINE THE GROUPS (No "users." prefix needed here)
    groups = {
      angelus = {
        gid = 1000;
      };
      deploy = { };
      acme = { };
      caddy = { }; # Ensure caddy group exists for the bridge
    };
  };

  programs.zsh.enable = true;
}
