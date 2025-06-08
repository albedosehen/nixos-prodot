{pkgs, ...}: {
  config = {
    environment.systemPackages = with pkgs; [
      (writeShellScriptBin "system-info" ''
        echo "=== System Information ==="
        echo "Hostname: $(hostname)"
        echo "Kernel: $(uname -r)"
        echo "Uptime: $(uptime -p)"
        echo "Memory: $(free -h | grep '^Mem:' | awk '{print $3 "/" $2}')"
        echo "Disk Usage: $(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}')"
        echo "Load Average: $(cat /proc/loadavg | cut -d' ' -f1-3)"
      '')

      (writeShellScriptBin "rebuild" ''
        set -euo pipefail
        echo "Rebuilding NixOS configuration..."
        sudo nixos-rebuild switch --flake .
        echo "System rebuild complete!"
      '')
    ];
  };
}
