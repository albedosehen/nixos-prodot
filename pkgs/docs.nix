{
  self,
  lib,
  pkgs,
  userConfig ? null,
  ...
}: let
  profileInfo =
    if userConfig != null
    then {
      hasProfile = true;
      profileName = userConfig.profileName or "unknown";
      capabilities = userConfig.capabilities or {};
      hostname = userConfig.user.hostname or "nixos";
      username = userConfig.user.username or "user";
    }
    else {
      hasProfile = false;
      profileName = "generic";
      capabilities = {};
      hostname = "nixos";
      username = "user";
    };

  capabilityDocs = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: enabled: "    - ${name}: ${
      if enabled
      then "✅ Enabled"
      else "❌ Disabled"
    }")
    profileInfo.capabilities
  );

  templateVars = {
    TITLE = "NixOS Profile-Based Dotfiles";
    REPO_URL = "https://github.com/albedosehen/nixos-prodot-files";
    PROFILE_CONTENT = if profileInfo.hasProfile then "\n- [Current Profile](./current-profile.md)" else "";
    CURRENT_PROFILE = profileInfo.profileName;
  };

  substituteTemplate = templateFile: outputFile: variables: ''
    substitute "${templateFile}" "${outputFile}" \
      ${lib.concatStringsSep " \\\n      " (lib.mapAttrsToList (name: value:
        "--replace '{{${name}}}' ${lib.escapeShellArg value}"
      ) variables)}
  '';

  currentProfileContent = 
    if profileInfo.hasProfile
    then ''
      # Current Profile Configuration

      **Active Profile**: ${profileInfo.profileName}
      **System**: ${profileInfo.username}@${profileInfo.hostname}

      ## Current Capabilities
  ${capabilityDocs}

      ## Profile-Specific Notes

      ${
        if profileInfo.profileName == "wsl"
        then ''
          WSL Profile Active

          **Available Commands:**
          - `just dev` - Enter development environment
          - Docker commands for containerization
          - Full language development stack

          **Windows Integration:**
          - Files accessible at `/mnt/c/`
          - Windows PATH integration enabled
          - Use Windows browsers & GUI tools

          **Networking:**
          - Firewall disabled (managed by Windows)
          - Use Windows networking tools
          - WSL2 provides network isolation
        ''
        else if profileInfo.profileName == "workstation"
        then ''
          Workstation Profile Active

          **Available Features:**
          - Complete desktop environment
          - GPU acceleration and CUDA support
          - Audio and Bluetooth functionality
          - Gaming and multimedia applications

          **Performance:**
          - Hardware acceleration enabled
          - High-performance computing ready
          - Docker and Kubernetes available
        ''
        else if profileInfo.profileName == "mobile"
        then ''
          Mobile Profile Active

          **Power Management:**
          - TLP enabled for battery optimization
          - Thermal management active
          - CPU frequency scaling configured

          **Security:**
          - Enhanced security features enabled
          - Kernel module locking active
          - Firewall configured for mobile use

          **Graphics:**
          - Hybrid graphics support (Intel + NVIDIA)
          - Power-saving graphics switching
        ''
        else ''
          Custom Profile Active

          You are running a custom profile: ${profileInfo.profileName}
        ''
      }
    ''
    else "";
in
  pkgs.stdenv.mkDerivation {
    pname = "nixos-prodot-docs";
    version = "1.0.0";

    src = self;

    buildInputs = with pkgs; [
      mdbook
      python312
    ];

    buildPhase = ''
      mkdir -p docs/src

      if [ ! -d "docs/templates" ]; then
        echo "❌ [docs:buildPhase]: Templates directory not found: docs/templates"
        echo "   Please ensure the template files exist in docs/templates/"
        exit 1
      fi

      # Generate docs
      ${substituteTemplate "docs/templates/SUMMARY.md.template" "docs/src/SUMMARY.md" templateVars}
      ${substituteTemplate "docs/templates/book.toml.template" "docs/book.toml" templateVars}
      ${substituteTemplate "docs/templates/introduction.md.template" "docs/src/introduction.md" templateVars}
      ${substituteTemplate "docs/templates/profiles.md.template" "docs/src/profiles.md" templateVars}
      ${substituteTemplate "docs/templates/installation.md.template" "docs/src/installation.md" templateVars}
      ${substituteTemplate "docs/templates/configuration.md.template" "docs/src/configuration.md" templateVars}
      ${substituteTemplate "docs/templates/switching.md.template" "docs/src/switching.md" templateVars}
      ${substituteTemplate "docs/templates/git-management.md.template" "docs/src/git-management.md" templateVars}
      ${substituteTemplate "docs/templates/modules.md.template" "docs/src/modules.md" templateVars}
      ${substituteTemplate "docs/templates/development.md.template" "docs/src/development.md" templateVars}
      ${substituteTemplate "docs/templates/testing.md.template" "docs/src/testing.md" templateVars}
      ${substituteTemplate "docs/templates/contributing.md.template" "docs/src/contributing.md" templateVars}

      # Generate profile-specific documentation if available
      ${
        if profileInfo.hasProfile
        then ''
          cat > docs/src/current-profile.md << 'EOF'
          ${currentProfileContent}
          EOF
        ''
        else ""
      }

      # Build the markdown
      cd docs
      mdbook build
    '';

    installPhase = ''
      mkdir -p $out

      if [ -d "book" ] && [ "$(ls -A book 2>/dev/null)" ]; then
        echo "[docs:installPhase]: Copying contents to book directory"
        cp -r book/* $out/
      else
        echo "[docs:installPhase]: Error: book directory is empty or doesn't exist"
        echo "Current working directory: $(pwd)"
        echo "Contents of current directory:"
        ls -la
        exit 1
      fi
    '';

    meta = with lib; {
      description = "Documentation for NixOS ProDot (Profile-Based Dotfiles) configuration";
      longDescription = ''
        This documentation provides an overview of the NixOS ProDot (Profile-Based Dotfiles) configuration system.
        It includes details on profiles, installation, configuration, and usage.
        The documentation is generated from templates and includes profile-specific information.
        The profiles supported include WSL, Workstation, Mobile, and Custom profiles.
      '';
      license = licenses.mit;
      platforms = platforms.all;
      maintainers = with maintainers; [ albedosehen ];
      homepage = "https://github.com/albedosehen/nixos-prodot";
    };
  }
