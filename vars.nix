{
  selected-profile = "wsl";

  user = {
    username = "<your-username>";
    hostname = "nixos";
  };

  gitProfiles = {
    default = "personal";

    personal = {
      userName = "<your-git-personal-username>";
      userEmail = "<your-git-personal-email>";
      signingKey = null;
      extraConfig = {};
    };

    work = {
      userName = "<your-git-work-username>";
      userEmail = "<your-git-work-email>";
      signingKey = null;
      extraConfig = {
        # Example: Use a specific SSH key for work repositories
        # core.sshCommand = "ssh -i ~/.ssh/id_rsa_work -o IdentitiesOnly=yes";
      };
    };
  };
}
