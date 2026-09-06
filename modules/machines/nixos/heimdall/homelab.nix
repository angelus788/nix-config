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

  # TEMPORARY: pocket-id failover rehearsal (2026-09-02). Pocket-id enforces
  # RFC 6749 §3.1.2 ("redirect_uri MUST NOT include a fragment component")
  # and unconditionally rejects the dashboard's default fragment-based
  # redirect_uri ("https://netbird.avgtechguy.com/#callback"), even when
  # registered verbatim as a callback URL - confirmed via direct /authorize
  # requests against pocket-id. AUTH_REDIRECT_URI overrides the frontend's
  # computed default with a fragment-free path instead.
  #
  # Must be a distinct PATH, not just "/" - @axa-fr/react-oidc's OidcRoutes
  # decides whether the current page load *is* the OAuth callback by
  # comparing getPath(currentUrl) === getPath(redirect_uri), where getPath()
  # returns path+hash with the trailing slash stripped. The default
  # "/#callback" hashes to "#callback", distinct from a normal page load's
  # "". A fragment-free "/" hashes to "" too - identical to every normal
  # page load - so the dashboard treated *every* visit as a callback attempt
  # and fired a bogus token exchange with code=undefined. "/oauth-callback"
  # keeps that comparison meaningful without a fragment; Caddy's SPA
  # try_files fallback serves the same app shell for any unmatched path, so
  # no separate route needs to exist server-side.
  #
  # Leave AUTH_SILENT_REDIRECT_URI unset - the oidc-client lib hard-errors
  # ("redirect_uri and silent_redirect_uri must be different") if both are
  # set to the same value, and an unset one just no-ops the silent-renew
  # feature rather than breaking login. Revert alongside the oidc.issuer/
  # scope override below once the rehearsal is done.
  services.netbird.server.dashboard.settings = {
    # Relative, not absolute - the frontend prepends window.location.origin
    # itself; an absolute URL here caused a duplicated origin
    # ("https://netbird.avgtechguy.comhttps://netbird.avgtechguy.com/").
    AUTH_REDIRECT_URI = "/oauth-callback";
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
      forgejo = {
        enable = true;
        oidc.pocketId = {
          enable = true;
          clientId = "forgejo";
          clientSecretFile = config.age.secrets.forgejoPid.path;
          clientSecretSourceFile = config.age.secrets.forgejoPid.file;
        };
      };
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
        # TEMPORARY: pocket-id failover rehearsal (2026-09-02). Keycloak's
        # own client_id/audience are already "netbird-dashboard", matching
        # pocket-id's, so only issuer/scope/idpSyncEnabled need overriding
        # here. idpSyncEnabled = false because pocket-id has no Keycloak-
        # compatible admin API - with it left on, management's per-request
        # IdpManagerConfig token fetch 200s into pocket-id's SPA fallback
        # HTML and every dashboard API call gets rejected as an invalid
        # JWT (see modules/homelab/services/netbird's idpSyncEnabled doc).
        # Revert this block (delete the whole oidc override) once the
        # rehearsal login + PAT-based admin promotion is done and
        # odin/Keycloak is back.
        oidc = {
          issuer = "https://id.avgtechguy.com";
          scope = "openid profile email offline_access";
          idpSyncEnabled = false;
        };
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

      pocket-id = {
        enable = true;
        encryptionKeyFile = config.age.secrets.pocketIdEncryptionKey.path;
      };

      #plausible = { # Deactivating Plausible
      #  enable = true;
      #  secretKeybaseFile = config.age.secrets.plausibleSecretKeybaseFile.path;
      #};
    };
  };
}
