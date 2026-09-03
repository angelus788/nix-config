{ inputs, ... }:
{
  age.secrets = {
    #cloudflareFirewallApiKey.file = "${inputs.secrets}/cloudflareFirewallApiKey.age";
    cloudflareDnsApiCredentials.file = "${inputs.secrets}/cloudflareDnsApiCredentials.age";
    #duckDNSDomain.file = "${inputs.secrets}/duckDNSDomain.age";
    #duckDNSToken.file = "${inputs.secrets}/duckDNSToken.age";
    hashedPasswordFile.file = "${inputs.secrets}/hashedUserPassword.age";
    initialHashedPassword.file = "${inputs.secrets}/initialHashedPassword.age";
    netbirdSetupKey.file = "${inputs.secrets}/netbirdSetupKey.age";
    sambaPassword.file = "${inputs.secrets}/sambaPassword.age";
    smbshared.file = "${inputs.secrets}/smbshared.age";
    syncthing-cert.file = "${inputs.secrets}/syncthing-cert-stormbreaker.age";
    syncthing-key.file = "${inputs.secrets}/syncthing-key-stormbreaker.age";
  };
}
