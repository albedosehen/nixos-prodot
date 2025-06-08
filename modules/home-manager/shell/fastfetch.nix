{pkgs, ...}: {
  home.packages = [pkgs.fastfetch];

  home.file.".config/fastfetch/config.jsonc".text = ''
    {
      "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
      "logo": {
        "source": "nixos",
        "color": {
          "1": "blue",
          "2": "cyan"
        }
      },
      "display": {
        "separator": " -> ",
        "color": {
          "keys": "blue",
          "title": "cyan"
        }
      },
      "modules": [
        {
          "type": "title",
          "color": {
            "user": "blue",
            "at": "white",
            "host": "cyan"
          }
        },
        "separator",
        "os",
        "host",
        "kernel",
        "uptime",
        "packages",
        "shell",
        "terminal",
        "cpu",
        "memory",
        "disk",
        "localip",
        "break",
        "colors"
      ]
    }
  '';
}
