{ config, lib, ... }:
{
  networking.hosts =
    let
      heimdallAddress = lib.removeSuffix "/24" config.homelab.networks.external.heimdall.v4.address;
    in
    {
      "${heimdallAddress}" = [
        config.homelab.services.forgejo.url
        config.homelab.services.forgejo-runner.atticUrl
        config.homelab.services.couchdb.url
      ];
    };
  security.acme.certs =
    let
      domain = "internalnetwork.party";
    in
    {
      "${domain}" = lib.mkForce {
        reloadServices = [ "caddy.service" ];
        domain = "${domain}";
        extraDomainNames = [ "*.${domain}" ];
        dnsProvider = "cloudflare";
        dnsResolver = "1.1.1.1:53";
        dnsPropagationCheck = true;
        group = config.services.caddy.group;
        environmentFile = config.age.secrets.cloudflareDnsApiCredentials.path;
        #environmentFile = config.homelab.cloudflare.dnsCredentialsFile;
      };
    };

  homelab = {
    baseDomain = "avgtechguy.com";
    cloudflare.dnsCredentialsFile = config.age.secrets.cloudflareDnsApiCredentialsAvgtechguy.path;
    frp = {
      tokenFile = config.age.secrets.frpToken.path;
      enable = true;
    };
    services = {
      enable = true;
      keycloak.role = "server";
      nextcloud.role = "server";
      navidrome.role = "server";
      miniflux.role = "server";
      microbin.role = "server";
      vaultwarden.role = "server";
      forgejo.enable = true;
      forgejo-runner = {
        enable = true;
        forgejoUrl = config.homelab.services.forgejo.url;
        tokenFile = config.age.secrets.forgejoRunnerTokenHeimdall.path;
        atticTokenFile = config.age.secrets.atticTokenHeimdall.path;
      };

      couchdb = {
        enable = true;
        couchdbUrl = config.homelab.services.couchdb.url;
        admin.passwordFile = config.age.secrets.couchdb-password.path;
      };
      matrix = {
        registrationSecretFile = config.age.secrets.matrixRegistrationSecret.path;
        enable = true;
      };

      netbird = {
        enable = true;
        role = "server";
        netbirdUrl = config.homelab.services.netbird.url;
        dns.domain = "thorsaga.net";
        proxy = {
          enable = true;
          domain = "proxy.avgtechguy.com";
          address = lib.head config.homelab.networks.external.heimdall.v4.extraAddresses;
          # DigitalOcean NATs the reserved IP's inbound traffic onto this
          # droplet's "anchor IP" before delivery, so the proxy container must
          # bind here rather than to `address` itself. Static for the
          # droplet's lifetime; re-check via
          # `curl 169.254.169.254/metadata/v1/interfaces/public/0/anchor_ipv4/address`
          # from the droplet if it's ever recreated/migrated.
          bindAddress = "10.17.0.5";
          interface = config.homelab.networks.external.heimdall.interface;
          caddyBindAddresses = [
            (lib.head (lib.splitString "/" config.homelab.networks.external.heimdall.v4.address))
          ];
          tokenFile = config.age.secrets.netbirdProxyToken.path;
          tokenSourceFile = config.age.secrets.netbirdProxyToken.file;
        };
      };

      rustdesk.enable = true;

      #plausible = { # Deactivating Plausible
      #  enable = true;
      #  secretKeybaseFile = config.age.secrets.plausibleSecretKeybaseFile.path;
      #};
    };
  };
}
