{
  inputs,
  ...
}:
let
  avatarPath = "${inputs.secrets}/avatar.jpeg";
  # Not config.homelab.user - that's the homelab *service* account
  # (default "share"), unrelated to the actual login/DE user.
  user = "angelus";
in
{
  # SDDM's Plasma-oriented themes (and KDE System Settings' own avatar
  # picker) read the user's icon via AccountsService, not the freedesktop
  # ~/.face convention (that's handled separately by
  # modules/dots/avatar for display managers that DO honor it). Plain
  # activation script rather than systemd.tmpfiles.rules since the INI
  # file needs real multi-line content, which tmpfiles' single-line
  # `f` rules can't express cleanly.
  system.activationScripts.userAvatar = ''
    mkdir -p /var/lib/AccountsService/icons /var/lib/AccountsService/users
    cp -f ${avatarPath} /var/lib/AccountsService/icons/${user}
    chmod 644 /var/lib/AccountsService/icons/${user}
    printf '[User]\nIcon=/var/lib/AccountsService/icons/%s\nSystemAccount=false\n' ${user} \
      > /var/lib/AccountsService/users/${user}
    chmod 644 /var/lib/AccountsService/users/${user}
  '';
}
