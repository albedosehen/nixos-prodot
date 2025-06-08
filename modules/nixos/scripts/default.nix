{pkgs, ...}: {
  switch-profile = pkgs.writeShellScriptBin "switch-profile" (builtins.readFile ./switch-profile.sh);
}
