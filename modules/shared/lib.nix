{
  pkgs,
  lib,
  ...
}: {
  # Extension functions for module configuration
  config = {
    _module.args.customLib = {
      mkIfElse = condition: thenValue: elseValue:
        if condition
        then thenValue
        else elseValue;

      mkScript = name: script: pkgs.writeShellScriptBin name script;

      mkDesktopItem = {
        name,
        exec,
        icon ? "",
        comment ? "",
        categories ? ["Application"],
      }:
        pkgs.makeDesktopItem {
          inherit name exec icon comment;
          desktopName = name;
          inherit categories;
        };

      mkSystemdService = {
        name,
        description,
        script,
        wantedBy ? ["multi-user.target"],
        after ? [],
        requires ? [],
      }: {
        systemd.services.${name} = {
          inherit description script wantedBy after requires;
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
        };
      };

      assertMsg = condition: message:
        assert lib.assertMsg condition message; true;

      mkMergeTopLevel = configs: lib.mkMerge (map (config: config) configs);
    };
  };
}
