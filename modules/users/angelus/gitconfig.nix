{
  inputs,
  lib,
  config,
  ...
}:
{
 # age.secrets.gitIncludes = {
 #   file = "${inputs.secrets}/gitIncludes.age";
 #   path = "$HOME/.config/git/includes";
 # };

  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Emilio S";
        email = "3382264+angelus788@users.noreply.github.com";
      };
      core = {
        sshCommand = "ssh -o 'IdentitiesOnly=yes' -i ~/.ssh/angelus";
      };
    };
    #includes = [
    #  {
    #    path = "~" + (lib.removePrefix "$HOME" config.age.secrets.gitIncludes.path);
    #    condition = "gitdir:~/Workspace/Projects/";
    #  }
    #];
  };
}
