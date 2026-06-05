{
  config,
  lib,
  ...
}:
let
  wg = config.homelab.networks.local.wireguard-ext;
  wgBase = lib.strings.removeSuffix ".1" wg.cidr.v4;
  hl = config.homelab;
in
{
  services.fail2ban-cloudflare = {
    enable = true;
    apiKeyFile = config.age.secrets.cloudflareFirewallApiKey.path;
    zoneId = "4fdfcf6fe7bc561019d20992e5a53eb1";
  };

  homelab = {
    enable = true;
    baseDomain = "internalnetwork.party";
    cloudflare.dnsCredentialsFile = config.age.secrets.cloudflareDnsApiCredentials.path;
    timeZone = "America/New_York";
    mounts = {
      config = "/persist/opt/services";
      slow = "/mnt/mergerfs_slow";
      fast = "/mnt/cache";
      merged = "/mnt/user";
    };
    frp = {
      enable = true;
      tokenFile = config.age.secrets.frpToken.path;
    };
    samba = {
      enable = true;
      passwordFile = config.age.secrets.sambaPassword.path;

      globalSettings = {
        "host msdfs" = "no";
        "msdfs root" = "no";
        "unix extensions" = "no";
        "wide links" = "yes";
        "allow insecure wide links" = "yes";
      };

      shares = {
        Backups = {
          path = "${hl.mounts.merged}/Backups";
        };
        Documents = {
          path = "${hl.mounts.fast}/Documents";
        };
        Media = {
          path = "${hl.mounts.merged}/Media";
        };
        Music = {
          path = "${hl.mounts.fast}/Media/Music";
        };
        Misc = {
          path = "${hl.mounts.merged}/Misc";
        };
        TimeMachine = {
          path = "${hl.mounts.fast}/TimeMachine";
          "fruit:time machine" = "yes";
        };
        YoutubeArchive = {
          path = "${hl.mounts.merged}/YoutubeArchive";
        };
        YoutubeCurrent = {
          path = "${hl.mounts.fast}/YoutubeCurrent";
        };
      };
    };
    services = {
      enable = true;
      slskd = {
        enable = true; # need to address WG0
        environmentFile = config.age.secrets.slskdEnvironmentFile.path;
      };

      forgejo-runner = {
        enable = true;
        forgejoUrl = "git.avgtechguy.com";
        tokenFile = config.age.secrets.forgejoRunnerTokenOdin.path;
        atticTokenFile = config.age.secrets.atticTokenHeimdall.path;
      };
      #backup = {
      #  enable = false;
      #  passwordFile = config.age.secrets.resticPassword.path;
      #  s3.enable = true;
      #  s3.url = "https://s3.eu-central-003.backblazeb2.com/angelus-ojfca-backups";
      #  s3.environmentFile = config.age.secrets.resticBackblazeEnv.path;
      #  local.enable = true;
      #};
      keycloak = {
        enable = true;
        dbPasswordFile = config.age.secrets.keycloakDbPasswordFile.path;
        oauth2ProxyEnvFile = config.age.secrets.oauth2ProxyEnvFile.path;
      };
      radicale = {
        enable = true;
        passwordFile = config.age.secrets.radicaleHtpasswd.path;
      };
      immich = {
        enable = true;
        mediaDir = "${hl.mounts.fast}/Media/Photos";
      };
      invoiceplane = {
        enable = false;
      };
      protonmail-bridge = {
        enable = true;
      };
      homepage = {
        enable = true;
        misc = [
          {
            PiKVM =
              let
                ip = config.homelab.networks.local.lan.reservations.pikvm.Address;
              in
              {
                href = "https://${ip}";
                siteMonitor = "https://${ip}";
                description = "Open-source KVM solution";
                icon = "pikvm.png";
              };
          }
          {
            Fios =
              let
                fios = config.homelab.networks.local.lan.reservations.fios.Address;
              in
              {
                href = "https://${fios}";
                siteMonitor = "https://${fios}";
                description = "Cable Modem WebUI";
                icon = "fios.png";
              };
          }
          {
            "Proxmox" = {
              href = "https://proxmox.internalnetwork.party";
              description = "Self-hosted virtualization platform designed for the provisioning of hyper-converged infrastructure.";
              icon = "proxmox.svg";
              siteMonitor = "https://proxmox.internalnetwork.party";
            };
          }
        ];
      };
      jellyfin.enable = true;
      paperless = {
        enable = true;
        passwordFile = config.age.secrets.paperlessPassword.path;
      };
      sabnzbd.enable = true;
      sonarr.enable = true;
      radarr.enable = true;
      bazarr.enable = true;
      prowlarr.enable = true;
      seerr = {
        enable = true;
      };
      nextcloud = {
        enable = true;
        admin = {
          username = "angelus";
          passwordFile = config.age.secrets.nextcloudAdminPassword.path;
        };
      };
      vaultwarden = {
        enable = true;
      };
      microbin = {
        enable = true;
      };
      miniflux = {
        enable = true;
        adminCredentialsFile = config.age.secrets.minifluxAdminPassword.path;
      };
      navidrome = {
        enable = true;
        environmentFile = config.age.secrets.navidromeEnv.path;
      };
      audiobookshelf.enable = true;
      deluge.enable = true;
      wireguard-netns = {
        enable = true;
        configFile = config.age.secrets.wireguardCredentials.path;
        privateIP = "${wgBase}.2/32";
        dnsIP = wg.dns;
        #dnsIP = wg.cidr.v4;
      };
    };
  };
}
