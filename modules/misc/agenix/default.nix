{
  inputs,
  ...
}:
{
  age = {
    secrets = {
      sambaPassword.file = "${inputs.secrets}/sambaPassword.age";
      cloudflareDnsApiCredentials.file = "${inputs.secrets}/cloudflareDnsApiCredentials.age";
      tailscaleAuthKey.file = "${inputs.secrets}/tailscaleAuthKey.age";
      resticBackblazeEnv.file = "${inputs.secrets}/resticBackblazeEnv.age";
      #tgNotifyCredentials.file = "${inputs.secrets}/tgNotifyCredentials.age";

     tgNotifyCredentials = {
      file = "${inputs.secrets}/tgNotifyCredentials.age";
      mode = "0440";
     };

      gitIncludes.file = "${inputs.secrets}/gitIncludes.age";
      frpToken.file = "${inputs.secrets}/frpToken.age";
    };
  };
}
