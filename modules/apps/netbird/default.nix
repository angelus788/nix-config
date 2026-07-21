{ config, pkgs, ... }:

{
  # NetBird Client Configuration
  services.netbird.clients.wt0 = {
    login = {
      enable = true;
      setupKeyFile = config.age.secrets.netbird-setup-key.path;
    };
    openFirewall = true;
  };

  # Optional: Required if you rely on NetBird client-side MagicDNS resolution
  services.resolved.enable = true;
}
