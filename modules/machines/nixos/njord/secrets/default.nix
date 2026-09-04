{ inputs, ... }:
{
  age.secrets = {
    #cloudflareFirewallApiKey.file = "${inputs.secrets}/cloudflareFirewallApiKey.age";
    cloudflareDnsApiCredentials.file = "${inputs.secrets}/cloudflareDnsApiCredentials.age";
    #duckDNSDomain.file = "${inputs.secrets}/duckDNSDomain.age";
    #duckDNSToken.file = "${inputs.secrets}/duckDNSToken.age";
    #hashedPasswordFile.file = "${inputs.secrets}/hashedUserPassword.age";
    #initialHashedPassword.file = "${inputs.secrets}/initialHashedPassword.age";
    syncthing-cert.file = "${inputs.secrets}/syncthing-cert-mayra.age";
    syncthing-key.file = "${inputs.secrets}/syncthing-key-mayra.age";
    netbirdSetupKey.file = "${inputs.secrets}/netbirdSetupKey.age";
  };
}
