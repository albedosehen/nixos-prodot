{pkgs, ...}: {
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    history = {
      size = 50000;
      save = 50000;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };

    sessionVariables = {
      ZSH_AUTOSUGGEST_STRATEGY = "(history completion)";
      ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE = "20";
    };

    initContent = ''
      setopt AUTO_CD
      setopt EXTENDED_GLOB
      setopt NOMATCH
      setopt NOTIFY
      setopt PROMPT_SUBST
      setopt CORRECT
      setopt COMPLETE_IN_WORD
      setopt ALWAYS_TO_END

      bindkey '^p' history-search-backward
      bindkey '^n' history-search-forward
      bindkey '^r' history-incremental-search-backward
      bindkey '^s' history-incremental-search-forward
      bindkey '^[[1;5C' forward-word
      bindkey '^[[1;5D' backward-word

      autoload -U compinit
      compinit

      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
      zstyle ':completion:*' list-colors ""
      zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
      zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

      if command -v direnv >/dev/null 2>&1; then
        eval "$(direnv hook zsh)"
      fi

      export DIRENV_LOG_FORMAT="";
      export DIRENV_LOG_LEVEL=error;
      export COLORTERM="truecolor"
      export EZA_ICON_SPACING=2
      export EZA_ICON_TYPE="nerd"
      export TERMINAL_FONT="FiraCode Nerd Font Mono"
      export LANG=en_US.UTF-8
      export LC_ALL=en_US.UTF-8

      # Source git profile environment if it exists
      if [[ -f "$HOME/.config/git-profile/env" ]]; then
        source "$HOME/.config/git-profile/env"
      fi

      # Git profile wrapper function
      # Use 'g' as a shortcut for git with profile support
      g() {
        if [[ -x "$HOME/.config/git-profile/git-with-profile" ]]; then
          "$HOME/.config/git-profile/git-with-profile" "$@"
        else
          git "$@"
        fi
      }

      # Completion for the g function
      compdef g=git

      fastfetch

      function ,,() {
          nix run "nixpkgs#$1" -- "''${@:2}"
      }

      function ,s() {
          nix shell "nixpkgs#$1" -- "''${@:2}"
      }

      portp() {
        sudo lsof -i :$1
      }

      killport() {
        sudo fuser -k $1/tcp
      }

      nix-cleanup() {
          nix-collect-garbage -d
          nix store optimise
          sudo nix-collect-garbage -d
          sudo nix store optimise
      }
    '';

    plugins = [
      {
        name = "vi-mode";
        src = pkgs.zsh-vi-mode;
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
      }
      {
        name = "zsh-nix-shell";
        file = "nix-shell.plugin.zsh";
        src = pkgs.fetchFromGitHub {
          owner = "chisui";
          repo = "zsh-nix-shell";
          rev = "v0.8.0";
          sha256 = "1lzrn0n4fxfcgg65v0qhnj7wnybybqzs4adz7xsrkgmcsr0ii8b7";
        };
      }
    ];
  };
}
