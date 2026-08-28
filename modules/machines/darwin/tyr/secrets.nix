{ inputs, ... }:
{
  age.secrets = {
    netbirdSetupKey.file = "${inputs.secrets}/netbirdSetupKey.age";
  };
}
