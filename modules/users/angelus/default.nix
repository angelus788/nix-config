{ pkgs
, ...
}:
{
  nix.settings.trusted-users = [ "angelus" "root" ];

  users = {
    users = {
      # Your existing user
      angelus = {
        shell = pkgs.zsh;
        uid = 1000;
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "users"
          "video"
          "podman"
          "input"
          "networkmanager"
        ];
        group = "angelus";
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII07ukuUm57yQYo2YL8GSLtPU8z9Q0NdU28d49wdoxbw"
        ];
      };

      # Add the acme user modification here
      acme = {
        extraGroups = [ "deploy" ];
      };
    };

    groups = {
      angelus = {
        gid = 1000;
      };

      # Add the deploy group here
      deploy = { };
    };
  };

  programs.zsh.enable = true;
}
