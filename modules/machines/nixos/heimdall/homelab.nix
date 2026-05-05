{ config, pkgs, lib, ... }:
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
      forgejo-runner = {
        enable = true;
        forgejoUrl = config.homelab.services.forgejo.url;
        tokenFile = config.age.secrets.forgejoRunnerTokenHeimdall.path;
        atticTokenFile = config.age.secrets.atticTokenHeimdall.path;
      };
      forgejo.enable = true;
      couchdb.enable = false;
      matrix = {
        registrationSecretFile = config.age.secrets.matrixRegistrationSecret.path;
        enable = true;
      };
      plausible = {
        enable = true;
        secretKeybaseFile = config.age.secrets.plausibleSecretKeybaseFile.path;
      };
    };
  };
}
