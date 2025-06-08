{
  pkgs,
  user,
  ...
}: {
  users = {
    defaultUserShell = pkgs.zsh;

    users.${user} = {
      isNormalUser = true;
      extraGroups = ["wheel" "docker" "networkmanager"];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [];
    };

    users.root = {
      hashedPassword = "!";
    };
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
    execWheelOnly = true;
  };
}
