{
  config,
  user,
  ...
}: {
  imports = [
    ./shell
    ./apps
  ];

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    stateVersion = "25.05";

    sessionVariables = {
      EDITOR = "nvim";
      BROWSER = "wslview";
      TERM = "xterm-256color";
      COLORTERM = "truecolor";
    };
  };

  programs = {
    home-manager.enable = true;
  };

  xdg = {
    enable = true;
    configHome = "${config.home.homeDirectory}/.config";
    cacheHome = "${config.home.homeDirectory}/.cache";
    dataHome = "${config.home.homeDirectory}/.local/share";
    stateHome = "${config.home.homeDirectory}/.local/state";
  };

  assertions = [
    {
      assertion = user != null && user != "";
      message = "Home-manager user must be defined";
    }
  ];
}
