{pkgs, ...}: {
  home.packages = [pkgs.bat];
  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      style = "numbers,changes,header";
      pager = "less -FR";
      map-syntax = [
        "*.jenkinsfile:Groovy"
        "*.props:Java Properties"
      ];
    };
    themes = {
      dracula = {
        src = builtins.fetchurl {
          url = "https://raw.githubusercontent.com/dracula/sublime/master/Dracula.tmTheme";
          sha256 = "0nlapygw0jwv1gvg9mkb47n3v6hq1i86y587h889sxd2ymygwrv7";
        };
      };
    };
    extraPackages = with pkgs.bat-extras; [
      batman
      batpipe
      batgrep
    ];
  };
}
