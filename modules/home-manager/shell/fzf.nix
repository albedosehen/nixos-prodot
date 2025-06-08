{pkgs, ...}: {
  home.packages = [pkgs.btop];
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [
      "--height 40%"
      "--border"
      "--reverse"
      "--inline-info"
    ];
  };
}
