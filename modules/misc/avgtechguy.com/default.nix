{ pkgs, ... }:
let
  domain = "avgtechguy.com";
in
{
  # 1. Firewall
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  # 2. Permissions & Directories
  systemd.tmpfiles.rules = [
    "d /var/www 0775 deploy deploy - -"
    "d /var/www/${domain} 0775 deploy deploy - -"
    "d /var/www/${domain}/public 0775 deploy deploy - -"
  ];

  # 3. Caddy Service
  services.caddy = {
    enable = true;
    email = "avgtechguy@mailbox.org";
    user = "deploy";
    group = "deploy";
    virtualHosts."${domain}" = {
      # Use a dedicated sub-folder like 'public' to keep SSH/config files hidden
      extraConfig = ''
        # Switch between these two lines for testing vs production:
                # root * /var/www/${domain}/public
                root * ${(pkgs.writeTextDir "index.html" "<h1>Coming Soon!</h1>")}

                file_server

                # Keep security active even during tests
                @hidden path */.*
                respond @hidden 403
      '';
    };
  };

  # 4. ACME Permission Bridge (Ensures Caddy can read certs)
  #security.acme.certs."${domain}".group = "caddy";

  # 5. Identities (Ensure these aren't duplicated in your common/default.nix)
  users = {
    users = {
      deploy = {
        isNormalUser = true;
        uid = 1001;
        group = "deploy";
        extraGroups = [
          "caddy"
          "acme"
          "wheel"
        ];
        shell = pkgs.zsh;
        home = "/var/www/${domain}";
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE1GM1paGkhF53Yfs1OhbRJeUE2GJQv7OHMwl4SF3r+s"
        ];
      };
      acme = {
        isSystemUser = true;
        group = "acme";
        extraGroups = [ "caddy" ];
      };
      caddy = {
        isSystemUser = true;
        group = "caddy";
        extraGroups = [ "deploy" ];
      };
    };
    groups = {
      deploy = { };
      acme = { };
      caddy = { };
    };
  };

}
