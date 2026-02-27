{ config
, ...
}:
let
  domain = "avgtechguy.com";
in
{
  systemd.tmpfiles.rules = [
    "d /var/www 0775 deploy deploy - -"
    "d /var/www/avgtechguy.com 0775 deploy deploy - -"
  ];

  services.caddy = {
    enable = true;
    email = "avgtechguy@mailbox.org";
    user = "deploy";
    group = "deploy";
    virtualHosts."${domain}" = {
      extraConfig = ''
        file_server
        root ${config.users.users.deploy.home}
      '';
    };
  };

  users.groups = {
    deploy = { };
  };
  users.users.deploy = {
    isNormalUser = true;
    home = "/var/www/avgtechguy.com";
    group = "deploy";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII07ukuUm57yQYo2YL8GSLtPU8z9Q0NdU28d49wdoxbw"
    ];
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

}
