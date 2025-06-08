{pkgs, ...}: {
  home.packages = with pkgs; [direnv];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;

    stdlib = ''
      use_devenv() {
        watch_file devenv.nix
        watch_file devenv.lock
        watch_file devenv.yaml
        watch_file flake.lock
        watch_file pyproject.toml
        watch_file uv.lock

        local max_attempts=3
        local attempt=1
        local timeout=300  # 5 minutes
        local result

        while [ $attempt -le $max_attempts ]; do
          result="$(timeout $timeout devenv shell --print-bash)" && {
            eval "$result"
            return 0
          }

          echo "Attempt $attempt failed, retrying..." >&2
          attempt=$((attempt + 1))
          sleep 5
        done

        echo "Failed to initialize devenv after $max_attempts attempts" >&2
        return 1
      }
    '';
  };
}
