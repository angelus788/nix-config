{ pkgs, config, lib, ... }:

{
  config = lib.mkIf config.myHomeDots.enableGui {
  programs.librewolf = {
    enable = true;
    # This links the bitwarden manifest into ~/.mozilla/native-messaging-hosts
    nativeMessagingHosts = [ pkgs.bitwarden-desktop ];
    };
  };

}
