{ inputs, ... }:
{
  age.secrets = {
    netbirdSetupKey.file = "${inputs.secrets}/netbirdSetupKey.age";
    tailscaleAuthKey.file = "${inputs.secrets}/tailscaleAuthKey.age";
  };
}
