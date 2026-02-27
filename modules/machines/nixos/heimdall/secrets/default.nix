{ inputs, lib, ... }:
{
  age.secrets = {
    wireguardPrivateKeyHeimdall = {
      file = "${inputs.secrets}/wireguardPrivateKeyHeimdall.age";
      owner = "systemd-network";
    };
    matrixRegistrationSecret = {
      owner = "matrix-synapse";
      group = "matrix-synapse";
      file = "${inputs.secrets}/matrixRegistrationSecret.age";
    };
    plausibleSecretKeybaseFile = {
      owner = "plausible";
      group = "plausible";
      file = "${inputs.secrets}/plausibleSecretKeybaseFile.age";
    };
    forgejoRunnerTokenHeimdall = {
      owner = "gitea-runner";
      group = "gitea-runner";
      file = "${inputs.secrets}/forgejoRunnerTokenHeimdall.age";
    };
    atticTokenHeimdall = {
      owner = "atticd";
      group = "atticd";
      file = "${inputs.secrets}/atticTokenFile.age";
    };
    smtpPassword = {
      owner = "angelus";
      group = lib.mkForce "forgejo";
      mode = "0440";
    };
    cloudflareDnsApiCredentialsAvgtechguy.file = "${inputs.secrets}/cloudflareDnsApiCredentialsAvgtechguy.age";

    #cloudflareFirewallApiKey.file = "${inputs.secrets}/cloudflareFirewallApiKey.age";
    #duckDNSDomain.file = "${inputs.secrets}/duckDNSDomain.age";
    #duckDNSToken.file = "${inputs.secrets}/duckDNSToken.age";
    #hashedPasswordFile.file = "${inputs.secrets}/hashedUserPassword.age";
    #initialHashedPassword.file = "${inputs.secrets}/initialHashedPassword.age";
    tailscaleAuthKey.file = "${inputs.secrets}/tailscaleAuthKey.age";
  };
}
