{ config, ... }:
{
  age.identityPaths = [
    "${config.home.homeDirectory}/.ssh/angelus"
    "/home/angelus/.ssh/angelus"
    "/Users/angelus/.ssh/angelus"
  ];
}
