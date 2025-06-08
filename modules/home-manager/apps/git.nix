{
  userConfig,
  lib,
  pkgs,
  ...
}: let
  gitProfiles = userConfig.gitProfiles or {};
  defaultProfile = gitProfiles.default or "personal";

  getCurrentGitProfile = let
    envProfile = builtins.getEnv "GIT_PROFILE";
    # Remove 'default' from the gitProfiles to avoid confusion, we'll use it as a key lookup
    availableProfiles = builtins.removeAttrs gitProfiles ["default"];
  in
    if envProfile != "" && availableProfiles ? ${envProfile}
    then availableProfiles.${envProfile}
    else if availableProfiles ? ${defaultProfile}
    then availableProfiles.${defaultProfile}
    else throw "Git profile '${defaultProfile}' not found in available profiles: ${builtins.toString (builtins.attrNames availableProfiles)}";

  currentGitConfig = getCurrentGitProfile;

  gitProfileSwitcher = pkgs.writeShellScriptBin "git-profile" ''
        #!/usr/bin/env bash
        set -euo pipefail

        # Available profiles from Nix configuration (shared across all system profiles)
        declare -A PROFILES
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (
        name: config: ''PROFILES["${name}"]="${config.userName} <${config.userEmail}>"''
      )
      (builtins.removeAttrs gitProfiles ["default"]))}

        show_help() {
          echo "Usage: git-profile [COMMAND] [PROFILE]"
          echo ""
          echo "Commands:"
          echo "  list, ls           List available git profiles"
          echo "  current, cur       Show current git profile"
          echo "  switch PROFILE     Switch to specified profile"
          echo "  help, -h, --help   Show this help message"
          echo ""
          echo "Note: Git profiles are shared across all system profiles (personal, work, server)"
          echo ""
          echo "Available profiles:"
          for profile in "''${!PROFILES[@]}"; do
            if [[ "$profile" == "${defaultProfile}" ]]; then
              echo "  $profile (default) - ''${PROFILES[$profile]}"
            else
              echo "  $profile - ''${PROFILES[$profile]}"
            fi
          done
        }

        list_profiles() {
          echo "Available git profiles (shared across all system profiles):"
          for profile in "''${!PROFILES[@]}"; do
            if [[ "$profile" == "${defaultProfile}" ]]; then
              echo "  $profile (default) - ''${PROFILES[$profile]}"
            else
              echo "  $profile - ''${PROFILES[$profile]}"
            fi
          done
        }

        current_profile() {
          local current_profile="''${GIT_PROFILE:-${defaultProfile}}"
          local git_user="$(git config --global user.name 2>/dev/null || echo 'Not set')"
          local git_email="$(git config --global user.email 2>/dev/null || echo 'Not set')"
          local ssh_command="$(git config --global core.sshCommand 2>/dev/null || echo 'Not set')"

          echo "Current git profile environment: $current_profile"
          if [[ -n "''${PROFILES[$current_profile]:-}" ]]; then
            echo "  Expected: ''${PROFILES[$current_profile]}"
          fi
          echo ""
          echo "Current git configuration:"
          echo "  User: $git_user"
          echo "  Email: $git_email"
          if [[ "$ssh_command" != "Not set" ]]; then
            echo "  SSH Command: $ssh_command"
          fi
          echo ""

          # Check if profile-specific config exists
          local profile_config="$HOME/.config/git-profile/config-$current_profile"
          if [[ -f "$profile_config" ]]; then
            echo "Profile-specific configuration found:"
            echo "  Config file: $profile_config"
            local profile_user="$(git config -f "$profile_config" user.name 2>/dev/null || echo 'Not set')"
            local profile_email="$(git config -f "$profile_config" user.email 2>/dev/null || echo 'Not set')"
            local profile_ssh="$(git config -f "$profile_config" core.sshCommand 2>/dev/null || echo 'Not set')"
            echo "  Profile User: $profile_user"
            echo "  Profile Email: $profile_email"
            if [[ "$profile_ssh" != "Not set" ]]; then
              echo "  Profile SSH Command: $profile_ssh"
            fi
            echo ""
            echo "To use this profile configuration:"
            echo "  Use: ~/.config/git-profile/git-with-profile instead of git"
            echo "  Or rebuild home-manager to apply globally: nh home switch ."
          else
            echo "No profile-specific configuration found."
            echo "Run 'git-profile switch $current_profile' to create it."
          fi
          echo ""

          # Show which profile this configuration matches
          ${lib.concatStringsSep "\n          " (lib.mapAttrsToList (
      name: config: ''
        if [[ "$git_user" == "${config.userName}" && "$git_email" == "${config.userEmail}" ]]; then
          echo "✓ Git configuration matches: ${name} profile"
        fi''
    ) (builtins.removeAttrs gitProfiles ["default"]))}

          # Check if no profile matched
          local profile_matched=false
          ${lib.concatStringsSep "\n          " (lib.mapAttrsToList (
      name: config: ''
        if [[ "$git_user" == "${config.userName}" && "$git_email" == "${config.userEmail}" ]]; then
          profile_matched=true
        fi''
    ) (builtins.removeAttrs gitProfiles ["default"]))}

          if [[ "$profile_matched" != "true" ]]; then
            echo "⚠ Git configuration doesn't match any known profile"
          fi
        }

        switch_profile() {
          local profile="$1"

          if [[ -z "''${PROFILES[$profile]:-}" ]]; then
            echo "Error: Profile '$profile' not found."
            echo "Available profiles: ''${!PROFILES[*]}"
            exit 1
          fi

          # Create git profile config directory if it doesn't exist
          mkdir -p "$HOME/.config/git-profile"

          # Set environment variable for current session
          export GIT_PROFILE="$profile"

          # Update the git profile environment file
          echo "export GIT_PROFILE=$profile" > "$HOME/.config/git-profile/env"

          # Get profile configuration from Nix configuration
          ${lib.concatStringsSep "\n      " (lib.mapAttrsToList (
      name: config: ''
        if [[ "$profile" == "${name}" ]]; then
          local user_name="${config.userName}"
          local user_email="${config.userEmail}"
          local ssh_command="${config.extraConfig.core.sshCommand or ""}"
        fi''
    ) (builtins.removeAttrs gitProfiles ["default"]))}

          # Create a temporary override config file
          local override_config="$HOME/.config/git-profile/config-$profile"
          cat > "$override_config" << EOF
    [user]
        name = $user_name
        email = $user_email
    EOF

          if [[ -n "$ssh_command" ]]; then
            cat >> "$override_config" << EOF
    [core]
        sshCommand = $ssh_command
    EOF
          fi

          # Create a wrapper script that uses the profile-specific config
          local git_wrapper="$HOME/.config/git-profile/git-with-profile"
          cat > "$git_wrapper" << 'EOF'
    #!/usr/bin/env bash
    # Git wrapper that applies profile-specific configuration

    # Source the git profile environment
    if [[ -f "$HOME/.config/git-profile/env" ]]; then
      source "$HOME/.config/git-profile/env"
    fi

    # Use profile-specific config if it exists
    profile_config="$HOME/.config/git-profile/config-''${GIT_PROFILE:-${defaultProfile}}"
    if [[ -f "$profile_config" ]]; then
      exec git -c "include.path=$profile_config" "$@"
    else
      exec git "$@"
    fi
    EOF
          chmod +x "$git_wrapper"

          echo "Switched to git profile: $profile"
          echo "  ''${PROFILES[$profile]}"
          echo "  Profile config: $override_config"
          echo ""
          echo "Git profile environment updated!"
          echo ""
          echo "To use this profile:"
          echo "  1. Start a new shell session or run: source ~/.config/git-profile/env"
          echo "  2. Use the git wrapper: ~/.config/git-profile/git-with-profile"
          echo "  3. Or rebuild home-manager to apply globally: nh home switch ."
        }

        case "''${1:-help}" in
          list|ls)
            list_profiles
            ;;
          current|cur)
            current_profile
            ;;
          switch)
            if [[ -z "''${2:-}" ]]; then
              echo "Error: Profile name required for switch command."
              echo "Usage: git-profile switch PROFILE"
              echo ""
              list_profiles
              exit 1
            fi
            switch_profile "$2"
            ;;
          help|-h|--help|*)
            show_help
            ;;
        esac
  '';
in {
  # Install the git profile switcher
  home.packages = [gitProfileSwitcher];

  programs.git = {
    enable = true;
    userName = currentGitConfig.userName;
    userEmail = currentGitConfig.userEmail;

    # Apply GPG signing if signingKey is provided
    signing = lib.mkIf (currentGitConfig.signingKey != null) {
      key = currentGitConfig.signingKey;
      signByDefault = true;
    };

    extraConfig = lib.recursiveUpdate {
      init.defaultBranch = "main";
      core = {
        editor = "vim";
        autocrlf = "input";
      };
      pull.rebase = true;
      push.autoSetupRemote = true;
      merge.conflictstyle = "diff3";
      diff.algorithm = "histogram";
      rerere.enabled = true;

      url = {
        "git@github.com:" = {
          insteadOf = "https://github.com/";
        };
      };
    } (currentGitConfig.extraConfig or {});

    aliases = {
      st = "status";
      co = "checkout";
      br = "branch";
      ci = "commit";
      ca = "commit -a";
      unstage = "reset HEAD --";
      last = "log -1 HEAD";
      visual = "!gitk";
      lg = "log --oneline --graph --decorate --all";
      amend = "commit --amend";
      undo = "reset --soft HEAD~1";

      # Add profile-related aliases
      profile = "!git-profile";
      whoami = "!echo \"$(git config user.name) <$(git config user.email)>\"";
    };

    delta = {
      enable = true;
      options = {
        navigate = true;
        light = false;
        side-by-side = true;
        line-numbers = true;
      };
    };

    ignores = [
      "*~"
      "*.swp"
      "*.swo"
      ".DS_Store"
      ".direnv/"
      "result"
      "result-*"
      "local.appsettings.json"
      "local.settings.json"
      ".env"
      "dist/"
      "node_modules/"
      "*.log"
      ".vscode/"
      ".idea/"
    ];
  };

  home.file.".ssh/config" = {
    text = ''
      # SSH configuration for git profiles
      # This configuration is generated from gitProfiles in vars.nix

      # Personal GitHub (default git hosting)
      Host github.com
        HostName github.com
        User git
        IdentityFile ~/.ssh/id_ed25519_git
        AddKeysToAgent yes

      # Work repositories (if work profile uses different SSH settings)
      Host bitbucket.org
        HostName bitbucket.org
        User git
        IdentityFile ~/.ssh/id_rsa_work
        AddKeysToAgent yes

      # Default settings for all hosts
      Host *
        ServerAliveInterval 60
        ServerAliveCountMax 3
        AddKeysToAgent yes
    '';
    target = ".ssh/config";
  };
}
