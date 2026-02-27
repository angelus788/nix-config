{ pkgs
, ...
}:
{
  nix.settings.trusted-users = [ "angelus" "root" ];

  users = {
    users = {
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
    };
    groups = {
      angelus = {
        gid = 1000;
      };
    };
  };
  programs.zsh.enable = true;

}
