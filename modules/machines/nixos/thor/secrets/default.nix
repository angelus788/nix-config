{ inputs, ... }:
{
  age.secrets = {
    #cloudflareFirewallApiKey.file = "${inputs.secrets}/cloudflareFirewallApiKey.age";
    duckDNSDomain.file = "${inputs.secrets}/duckDNSDomain.age";
    duckDNSToken.file = "${inputs.secrets}/duckDNSToken.age";
    hashedPasswordFile.file = "${inputs.secrets}/hashedUserPassword.age";
    hermesDashboardAuth.file = "${inputs.secrets}/hermesDashboardAuth.age";
    initialHashedPassword.file = "${inputs.secrets}/initialHashedPassword.age";
    netbirdSetupKey.file = "${inputs.secrets}/netbirdSetupKey.age";
  };
}
