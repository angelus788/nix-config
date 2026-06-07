{ inputs, ... }:
{
  age.secrets = {
    #cloudflareFirewallApiKey.file = "${inputs.secrets}/cloudflareFirewallApiKey.age";
    #duckDNSDomain.file = "${inputs.secrets}/duckDNSDomain.age";
    #duckDNSToken.file = "${inputs.secrets}/duckDNSToken.age";
    #hashedPasswordFile.file = "${inputs.secrets}/hashedUserPassword.age";
    #initialHashedPassword.file = "${inputs.secrets}/initialHashedPassword.age";
    syncthing-cert.file = "${inputs.secrets}/syncthing-cert-mayra.age";
    syncthing-key.file = "${inputs.secrets}/syncthing-key-mayra.age";
    tailscaleAuthKey.file = "${inputs.secrets}/tailscaleAuthKey.age";
  };
}
