{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  service = "forgejo";
  cfg = config.homelab.services.${service};
  hl = config.homelab;
in
{
  options.homelab.services.${service} = {
    enable = lib.mkEnableOption {
      description = "Enable ${service}";
    };
    url = lib.mkOption {
      type = lib.types.str;
      default = "git.${hl.baseDomain}";
    };
    homepage.name = lib.mkOption {
      type = lib.types.str;
      default = "Forgejo";
    };
    homepage.description = lib.mkOption {
      type = lib.types.str;
      default = "A painless, self-hosted Git service";
    };
    homepage.icon = lib.mkOption {
      type = lib.types.str;
      default = "forgejo.svg";
    };
    homepage.category = lib.mkOption {
      type = lib.types.str;
      default = "Services";
    };
  };
  config = lib.mkIf cfg.enable {
    services.openssh.settings.AcceptEnv = [ "GIT_PROTOCOL" ];

    services.openssh.extraConfig = ''
      Match User forgejo
        AuthorizedKeysCommand ${config.services.forgejo.package}/bin/forgejo keys -c /var/lib/forgejo/custom/conf/app.ini -e forgejo -u %u -t %t -k %k
        AuthorizedKeysCommandUser forgejo
    '';

    services.forgejo = {
      package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.forgejo;
      enable = true;
      database.type = "postgres";
      lfs.enable = true;
      settings = {
        server = {
          DOMAIN = cfg.url;
          ROOT_URL = "https://${cfg.url}/";
          HTTP_PORT = 3000;
          LANDING_PAGE = "/avgtechguy";
          SSH_PORT = lib.head config.services.openssh.ports;
          START_SSH_SERVER = false;
        };
        
        ssh = {
          # Ensures Forgejo maintains /var/lib/forgejo/.ssh/authorized_keys
          CREATE_AUTHORIZED_KEYS_FILE = true;
          # Disables token verification modal so keys/deploy keys add seamlessly in UI
          ENABLE_SSH_KEY_VERIFICATION = false;
        };

        log = {
          LEVEL = "Trace";
        };
        service = {
          DISABLE_REGISTRATION = true;
          ENABLE_NOTIFY_MAIL = true;
          REGISTER_EMAIL_CONFIRM = true;
        };
        mailer = {
          ENABLED = true;
          FROM = config.email.fromAddress;
          PROTOCOL = "sendmail";
          SENDMAIL_PATH = "/run/wrappers/bin/sendmail";
        };
      };
    };
    services.caddy.virtualHosts."${cfg.url}" = {
      useACMEHost = hl.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:${toString config.services.forgejo.settings.server.HTTP_PORT}
        request_body {
          max_size 10GB
        }
      '';
    };
  };
}
