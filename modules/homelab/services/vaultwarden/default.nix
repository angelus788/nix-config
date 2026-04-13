{ config, lib, pkgs, ... }:
let
  service = "vaultwarden";
  cfg = config.homelab.services.${service};
  hl = config.homelab;
in
{
  options.homelab.services.${service} = {
    enable = lib.mkEnableOption "Enable ${service}";
    configDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/bitwarden_rs";
    };
    url = lib.mkOption {
      type = lib.types.str;
      default = "pass.internalnetwork.party";
    };
    role = lib.mkOption {
      type = lib.types.enum [ "client" "server" ];
      default = "client";
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

  config = lib.mkIf cfg.enable (lib.mkMerge [
    # --- CLIENT CONFIGURATION (Odin) ---
    (lib.mkIf (cfg.role == "client") {
      systemd.tmpfiles.rules = [
        "d ${cfg.configDir} 0750 vaultwarden vaultwarden -"
      ];

      systemd.services.vaultwarden.serviceConfig = {
        ReadOnlyPaths = [ "/nix/store" ];
        ReadWritePaths = [ cfg.configDir ];
        PrivateUsers = lib.mkForce false;
        StateDirectory = lib.mkForce (baseNameOf cfg.configDir);
        ProtectSystem = lib.mkForce "true";
      };

      services.vaultwarden = {
        enable = true;
        webVaultPackage = pkgs.vaultwarden.webvault;
        config = {
          DOMAIN = "https://${cfg.url}";
          DATA_FOLDER = cfg.configDir;
          ROCKET_ADDRESS = "127.0.0.1";
          ROCKET_PORT = 8222;
          WEB_VAULT_ENABLED = true;
          WEB_VAULT_FOLDER = "${pkgs.vaultwarden.webvault}/share/vaultwarden/vault";
          EXTENDED_LOGGING = true;
          LOG_LEVEL = "info";
        };
      };

      services.frp.settings.proxies = [
        {
          name = service;
          type = "tcp";
          localIP = "127.0.0.1";
          localPort = 8222;
          remotePort = 8222;
        }
      ];
    })

    # --- SERVER CONFIGURATION (Heimdall) ---
    (lib.mkIf (cfg.role == "server") (lib.mkMerge [
      {
        services.caddy.virtualHosts."${cfg.url}" = {
          useACMEHost = "internalnetwork.party";
          extraConfig = ''
            reverse_proxy http://127.0.0.1:8222
          '';
        };
      }

      # The Fix: Use setAttrByPath to hide the attribute from the static evaluator.
      # This prevents Odin from ever trying to validate the 'fail2ban-cloudflare' path.
      (lib.setAttrByPath [ "services" "fail2ban-cloudflare" "jails" "vaultwarden" ] {
        serviceName = "vaultwarden";
        failRegex = "^.*Username or password is incorrect. Try again. IP: <HOST>. Username: <F-USER>.*</F-USER>.$";
      })
    ]))
  ]);
}
