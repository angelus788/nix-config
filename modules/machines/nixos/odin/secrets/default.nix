{ inputs, ... }:
{
  age.secrets = {
    cloudflareFirewallApiKey.file = "${inputs.secrets}/cloudflareFirewallApiKey.age";
    duckDNSDomain.file = "${inputs.secrets}/duckDNSDomain.age";
    duckDNSToken.file = "${inputs.secrets}/duckDNSToken.age";
    keycloakDbPasswordFile.file = "${inputs.secrets}/keycloakDbPasswordFile.age";
    keycloakCloudflared.file = "${inputs.secrets}/keycloakCloudflared.age";
    hashedPasswordFile.file = "${inputs.secrets}/hashedUserPassword.age";
    initialHashedPassword.file = "${inputs.secrets}/initialHashedPassword.age";
    radicaleHtpasswd.file = "${inputs.secrets}/radicaleHtpasswd.age";
    resticPassword = {
      file = "${inputs.secrets}/resticPassword.age";
      owner = "restic";
    };
    slskdEnvironmentFile = {
      file = "${inputs.secrets}/slskdEnviromentFile.age";
      owner = "share";
  };
    tailscaleAuthKey.file = "${inputs.secrets}/tailscaleAuthKey.age";
  };
}
