{config, pkgs, ... }:

{
   # 1Password
  programs = {
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "angelus" ];
    };
  };

  environment.etc = {
    "1password/custom_allowed_browsers" = {
      text = ''
        vivaldi-bin
        librewolf
        zen
      '';
      mode = "0755";
    };
  };





}