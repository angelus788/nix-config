{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.homelab;
in
{
  options.homelab = {
    services = {
      enable = lib.mkEnableOption "Settings and services for the homelab";
    };
    frp = {
      enable = lib.mkEnableOption "Settings and services for the homelab";
      serverHostname = lib.mkOption {
        type = lib.types.str;
        description = "A hostname entry in the config.homelab.network.external which should be used as a server";
        default = "heimdall";
      };
      tokenFile = lib.mkOption {
        type = lib.types.str;
        example = lib.literalExpression ''
          pkgs.writeText "token.txt" '''
            12345678
          '''
        '';
      };
    };
  };

  config = lib.mkIf config.homelab.services.enable {
    # === INSERTED AGENIX / FRP CONFIGURATION HERE ===
    homelab.frp = {
      enable = true;
      tokenFile = config.age.secrets.frpToken.path;
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ]
    ++ (lib.optionals
      (
        config.networking.hostName == cfg.frp.serverHostname && config.homelab.frp.enable
      ) [ 7000 ]);

    systemd.services =
      let
        acmeFix = {
          path = [
            pkgs.diffutils
            pkgs.findutils
            pkgs.gnugrep
            pkgs.coreutils
            pkgs.lego
          ];
          serviceConfig = {
            User = lib.mkForce "acme";
            Group = lib.mkForce config.services.caddy.group;
            EnvironmentFile = lib.mkForce config.homelab.cloudflare.dnsCredentialsFile;
          };
        };
        # Safe list of domains to generate unique overrides for
        domains = [
          config.homelab.baseDomain
          "avgtechguy.com"
          "internalnetwork.party"
          "thorsaga.net"
        ];
        acmeServices = lib.listToAttrs (map
          (domain: {
            name = "acme-order-renew-${domain}";
            value = acmeFix;
          })
          (lib.unique domains));
      in
      {
        # Your existing frp service credential loading (safely migrated inside)
        "frp-${config.networking.hostName}".serviceConfig.LoadCredential =
          lib.mkIf config.homelab.frp.enable "frpToken:${cfg.frp.tokenFile}";
      } // acmeServices;
    services.frp.instances.${config.networking.hostName} = lib.mkIf config.homelab.frp.enable {
      enable = true;
      role = if (config.networking.hostName == cfg.frp.serverHostname) then "server" else "client";
      settings =
        let
          common = {
            auth.tokenSource.type = "file";
            # Dynamic systemd credential directory resolution
            auth.tokenSource.file.path = "{{ .Envs.CREDENTIALS_DIRECTORY }}/frpToken";
          };
        in
        if (config.networking.hostName == cfg.frp.serverHostname) then
          {
            bindAddr = "0.0.0.0";
            bindPort = 7000;
          }
          // common
        else
          {
            serverAddr =
              builtins.head (lib.splitString "/"
                config.homelab.networks.external.${cfg.frp.serverHostname}.v4.address);
            serverPort = 7000;
          }
          // common;
    };
    security.acme = {
      acceptTerms = true;
      defaults.email = "avgtechguy@mailbox.org";
      certs.${config.homelab.baseDomain} = {
        reloadServices = [ "caddy.service" ];
        domain = "${config.homelab.baseDomain}";
        extraDomainNames = [ "*.${config.homelab.baseDomain}" ];
        dnsProvider = "cloudflare";
        dnsResolver = "1.1.1.1:53";
        dnsPropagationCheck = true;
        group = config.services.caddy.group;
        environmentFile = config.homelab.cloudflare.dnsCredentialsFile;
      };
    };
    services.caddy = {
      enable = true;
      globalConfig = ''
        auto_https off
      '';
      virtualHosts = {
        # Simplified redirect block
        "http://${config.homelab.baseDomain}, http://*.${config.homelab.baseDomain}" = {
          extraConfig = ''
            redir https://{host}{uri}
          '';
        };

      };
    };
    nixpkgs.config.permittedInsecurePackages = [
      "dotnet-sdk-6.0.428"
      "aspnetcore-runtime-6.0.36"
    ];
    virtualisation.podman = {
      dockerCompat = true;
      autoPrune.enable = true;
      extraPackages = [ pkgs.zfs ];
      defaultNetwork.settings = {
        dns_enabled = true;
      };
    };
    virtualisation.oci-containers = {
      backend = "podman";
    };

    networking.firewall.interfaces.podman0.allowedUDPPorts =
      lib.lists.optionals config.virtualisation.podman.enable
        [ 53 ];
  };

  imports = [
    ./arr/prowlarr
    ./arr/bazarr
    ./arr/seerr
    ./arr/sonarr
    ./arr/radarr
    ./arr/lidarr
    ./audiobookshelf
    ./couchdb
    ./deluge
    ##./deemix
    ./forgejo
    ./forgejo-runner
    ./hermes-agent
    ./homepage
    ./immich
    ./invoiceplane
    ./jellyfin
    ./keycloak
    ./matrix
    ./plausible
    ./microbin
    ./miniflux
    ./monitoring/grafana
    ./monitoring/prometheus
    ./monitoring/prometheus/exporters/shelly_plug_exporter
    ./navidrome
    ./nextcloud
    ./netbird
    ./pocket-id
    ./smarthome/homeassistant
    ./smarthome/raspberrymatic
    ./protonmail-bridge
    ./paperless-ngx
    ./radicale
    ./rustdesk
    ./sabnzbd
    ./slskd
    ./uptime-kuma
    ./vaultwarden
    ./wireguard-netns
  ];
}
