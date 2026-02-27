{ config, lib, ... }:
{
  networking.hosts =
    let
      heimdall = config.hostName;
      #heimdallAddress = lib.removeSuffix "/24" config.homelab.networks.external.heimdall.v4.address;
      # This provides a fallback empty string if the attribute is missing
      heimdallAddress = lib.removeSuffix "/24" (config.homelab.networks.external.heimdall.v4.address or "127.0.0.1/24");
    in
    {
      "${heimdallAddress}" = [
        config.homelab.services.forgejo.url
        config.homelab.services.forgejo-runner.atticUrl
      ];
    };
  security.acme.certs =
    let
      domain = "internalnetwork.party";
    in
    {
      "${domain}" = {
        reloadServices = [ "caddy.service" ];
        domain = "${domain}";
        extraDomainNames = [ "*.${domain}" ];
        dnsProvider = "cloudflare";
        dnsResolver = "1.1.1.1:53";
        dnsPropagationCheck = true;
        group = config.services.caddy.group;
        environmentFile = config.homelab.cloudflare.dnsCredentialsFile;
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
      forgejo-runner = {
        enable = true;
        forgejoUrl = config.homelab.services.forgejo.url;
        tokenFile = config.age.secrets.forgejoRunnerTokenHeimdall.path;
        atticTokenFile = config.age.secrets.atticTokenHeimdall.path;
      };
      forgejo.enable = true;
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
