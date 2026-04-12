{ config, lib, ... }:
let
  service = "vaultwarden";
  cfg = config.homelab.services.${service};
in
{
  options.homelab.services.${service} = {
    enable = lib.mkEnableOption {
      description = "Enable ${service}";
    };
    configDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/bitwarden_rs";
    };
    url = lib.mkOption {
      type = lib.types.str;
      default = "pass.internalnetwork.party";
    };
    homepage.name = lib.mkOption {
      type = lib.types.str;
      default = "Vaultwarden";
    };
    homepage.description = lib.mkOption {
      type = lib.types.str;
      default = "Password manager";
    };
    homepage.icon = lib.mkOption {
      type = lib.types.str;
      default = "bitwarden.svg";
    };
    homepage.category = lib.mkOption {
      type = lib.types.str;
      default = "Services";
    };
  };
  config = lib.mkIf cfg.enable {

    systemd.tmpfiles.rules = [
      "d ${cfg.configDir} 0750 vaultwarden vaultwarden -"
    ];

    services = {
      fail2ban-cloudflare = lib.mkIf config.services.fail2ban-cloudflare.enable {
        jails = {
          vaultwarden = {
            serviceName = "vaultwarden";
            failRegex = "^.*Username or password is incorrect. Try again. IP: <HOST>. Username: <F-USER>.*</F-USER>.$";
          };
        };
      };
      ${service} = {
        enable = true;
        config = {
          DOMAIN = "https://${cfg.url}";
          WEB_VAULT_ENABLED = true;
          SIGNUPS_ALLOWED = false;
          ROCKET_ADDRESS = "127.0.0.1";
          ROCKET_PORT = 8222;
          EXTENDED_LOGGING = true;
          LOG_LEVEL = "warn";
        };
      };
      caddy.virtualHosts."${cfg.url}" = {
        useACMEHost = "internalnetwork.party";
        extraConfig = ''
          tls /var/lib/acme/internalnetwork.party/cert.pem /var/lib/acme/internalnetwork.party/key.pem
          
          reverse_proxy 127.0.0.1:8222 {
            header_up Host {host}
            header_up X-Real-IP {remote_host}
          }
        '';
      };
    };
  };

}
#reverse_proxy http://${config.services.${service}.config.ROCKET_ADDRESS}:${
#           toString config.services.${service}.config.ROCKET_PORT
