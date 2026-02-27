{ pkgs, ... }:

{
  programs.firefox = {
    enable = true;
    # This links the bitwarden manifest into ~/.mozilla/native-messaging-hosts
    nativeMessagingHosts = [ pkgs.bitwarden-desktop ];
  };
  programs.librewolf = {
    enable = true;
    # This links the bitwarden manifest into ~/.mozilla/native-messaging-hosts
    nativeMessagingHosts = [ pkgs.bitwarden-desktop ];
  };

}
