{ inputs, ... }:
{
  age.secrets = {
    cloudflareFirewallApiKey.file = "${inputs.secrets}/cloudflareFirewallApiKey.age";

    cloudflareDnsApiCredentials.file = "${inputs.secrets}/cloudflareDnsApiCredentials.age";
    cloudflareDnsApiCredentialsAvgtechguy.file = "${inputs.secrets}/cloudflareDnsApiCredentialsAvgtechguy.age";

    #borgBackupKey.file = "${inputs.secrets}/borgBackupKey.age";
    #borgBackupSSHKey.file = "${inputs.secrets}/borgBackupSSHKey.age";
    duckDNSDomain.file = "${inputs.secrets}/duckDNSDomain.age";
    duckDNSToken.file = "${inputs.secrets}/duckDNSToken.age";
    keycloakDbPasswordFile.file = "${inputs.secrets}/keycloakDbPasswordFile.age";
    keycloakCloudflared.file = "${inputs.secrets}/keycloakCloudflared.age";
    hashedPasswordFile.file = "${inputs.secrets}/hashedUserPassword.age";
    initialHashedPassword.file = "${inputs.secrets}/initialHashedPassword.age";
    invoicePlaneDbPasswordFile.file = "${inputs.secrets}/invoicePlaneDbPasswordFile.age";
    #microbinCloudflared.file = "${inputs.secrets}/microbinCloudflared.age";
    minifluxAdminPassword.file = "${inputs.secrets}/minifluxAdminPassword.age";
    navidromeEnv.file = "${inputs.secrets}/navidromeEnv.age";
    nextcloudAdminPassword.file = "${inputs.secrets}/nextcloudAdminPassword.age";
    nextcloudCloudflared.file = "${inputs.secrets}/nextcloudCloudflared.age";
    oauth2ProxyEnvFile = {
      file = "${inputs.secrets}/oauth2ProxyEnvFile.age";
      owner = "oauth2-proxy";
      group = "oauth2-proxy";
    };
    paperlessPassword.file = "${inputs.secrets}/paperlessPassword.age";
    paperlessWebdav.file = "${inputs.secrets}/paperlessWebdav.age";
    radicaleHtpasswd.file = "${inputs.secrets}/radicaleHtpasswd.age";
    #resticPassword = {
    #  file = "${inputs.secrets}/resticPassword.age";
    #  owner = "restic";
    #};
    slskdEnvironmentFile = {
      file = "${inputs.secrets}/slskdEnvironmentFile.age";
      owner = "share";
    };
    tailscaleAuthKey.file = "${inputs.secrets}/tailscaleAuthKey.age";
    vaultwardenCloudflared.file = "${inputs.secrets}/vaultwardenCloudflared.age";
    wireguardCredentials.file = "${inputs.secrets}/wireguardCredentials.age";
  };
}
