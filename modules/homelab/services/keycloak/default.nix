{
  config,
  lib,
  pkgs,
  ...
}:
let
  service = "keycloak";
  cfg = config.homelab.services.${service};
in
{
  options.homelab.services.${service} = {
    enable = lib.mkEnableOption {
      description = "Enable ${service}";
    };
    url = lib.mkOption {
      type = lib.types.str;
      default = "login.internalnetwork.party";
    };
    homepage.name = lib.mkOption {
      type = lib.types.str;
      default = "Keycloak";
    };
    homepage.description = lib.mkOption {
      type = lib.types.str;
      default = "Open Source Identity and Access Management";
    };
    homepage.icon = lib.mkOption {
      type = lib.types.str;
      default = "keycloak.svg";
    };
    homepage.category = lib.mkOption {
      type = lib.types.str;
      default = "Services";
    };
    dbPasswordFile = lib.mkOption {
      type = lib.types.path;
    };
    role = lib.mkOption {
      type = lib.types.enum [
        "client"
        "server"
      ];
      default = "client";
    };
  };
  config =
    let
      mkIfElse =
        p: yes: no:
        lib.mkMerge [
          (lib.mkIf p yes)
          (lib.mkIf (!p) no)
        ];
    in
    mkIfElse (cfg.role == "client")
      # client
      (lib.mkIf cfg.enable {
        environment.systemPackages = [
          pkgs.keycloak
          pkgs.custom_keycloak_themes.notthebee
        ];
        nixpkgs.overlays = [
          (_final: _prev: {
            custom_keycloak_themes = {
              notthebee = pkgs.callPackage ./theme.nix { };
            };
            custom_keycloak_plugins = {
              keycloak_spi_trusted_device = pkgs.callPackage ./trusted-device.nix { };
            };
          })
        ];
        services.${service} = {
          enable = true;
          initialAdminPassword = "schneke123";
          database.passwordFile = cfg.dbPasswordFile;
          themes = {
            notthebee = pkgs.custom_keycloak_themes.notthebee;
          };
          plugins = [ pkgs.custom_keycloak_plugins.keycloak_spi_trusted_device ];
          settings = {
            spi-theme-static-max-age = "-1";
            spi-theme-cache-themes = false;
            spi-theme-cache-templates = false;
            http-port = 8821;
            hostname = cfg.url;
            hostname-strict = false;
            hostname-strict-https = false;
            proxy-headers = "xforwarded";
            http-relative-path = "/";
            http-enabled = true;
          };
        };
        services.frp.instances.${config.networking.hostName}.settings.proxies = [
          {
            name = service;
            type = "tcp";
            localIP = "127.0.0.1";
            localPort = 8821;
            remotePort = 8821;
          }
        ];
      })
      # server
      {
        services.caddy.virtualHosts."${cfg.url}" = {
          useACMEHost = "internalnetwork.party";
          extraConfig = ''
            reverse_proxy http://127.0.0.1:8821 {
                header_up Host {host}
                header_up X-Real-IP {remote_host}
            }
          '';
        };
      };
}
