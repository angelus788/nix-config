{ config, ... }:
{
  age.identityPaths = [ "${config.home.homeDirectory}/.ssh/angelus" ];
}
