{ inputs, ... }:
{
  # Freedesktop.org's ~/.face convention - honored by some display
  # managers (LightDM, some GDM setups). SDDM/Plasma (this repo's actual
  # DE hosts) reads the user avatar via AccountsService instead - see
  # modules/misc/user-avatar for that piece.
  home.file.".face".source = "${inputs.secrets}/avatar.jpeg";
}
