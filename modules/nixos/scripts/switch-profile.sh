#!/usr/bin/env bash
# shellcheck shell=bash

# Simple script for switching NixOS Profiles defined in profiles.nix
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# Navigate to flake root (3 levels up from modules/nixos/scripts/)
FLAKE_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
FLAKE_FILE="$FLAKE_DIR/flake.nix"
VARS_FILE="$FLAKE_DIR/vars.nix"
PROFILES_FILE="$FLAKE_DIR/profiles.nix"

# Dynamically get available profiles from profiles.nix
get_available_profiles() {
  if [[ -f $PROFILES_FILE ]] && command -v nix >/dev/null 2>&1; then
    # Use nix to get the attribute names from profiles.nix (without JSON for simpler parsing)
    local profiles_raw
    profiles_raw=$(nix eval --file "$PROFILES_FILE" --apply 'profiles: builtins.attrNames profiles' 2>/dev/null || echo '[ "wsl" "workstation" "mobile" ]')
    # Parse the nix list format [ "item1" "item2" "item3" ]
    echo "$profiles_raw" | sed 's/\[ *//; s/ *\]//; s/"//g' | tr ' ' '\n' | grep -v '^$'
  else
    # Fallback if nix is not available or profiles.nix doesn't exist
    printf "wsl\nworkstation\nmobile\n"
  fi
}

# Cache profiles array for performance
mapfile -t PROFILES < <(get_available_profiles)

show_usage() {
  echo -e "${BLUE}NixOS Profile Switcher${NC}"
  echo "Use the profiles.nix and vars.nix files to define your own named profiles."
  echo
  echo "Usage: $0 [profile] [options]"
  echo
  echo "Available Profiles:"
  for profile in "${PROFILES[@]}"; do
    case $profile in
    wsl)
      echo "  wsl         - WSL2 development environment (Windows Subsystem for Linux)"
      ;;
    workstation)
      echo "  workstation - Full NixOS desktop with GPU support and development tools"
      ;;
    mobile)
      echo "  mobile      - NixOS laptop with power management and hybrid graphics"
      ;;
    *)
      echo "  $profile      - Custom profile"
      ;;
    esac
  done
  echo
  echo "Options:"
  echo "  -h, --help     - Show this help message"
  echo "  -l, --list     - List available profiles and their configs"
  echo "  -c, --current  - Show current profile"
  echo "  -d, --dry-run  - Show what would change without applying"
  echo "  --rebuild      - Rebuild system after switching profile"
  echo
  echo "Examples:"
  echo "  $0 wsl                # Switch to WSL development profile"
  echo "  $0 workstation --rebuild  # Switch to workstation and rebuild"
  echo "  $0 --current          # Show current profile"
  echo "  $0 --list             # List all profiles with details"
  echo
  echo "Git Profile Management:"
  echo "  Each system profile uses shared git profiles from vars.nix."
  echo "  Use the 'git-profile' command to switch between git profiles:"
  echo "    git-profile list            # List available git profiles"
  echo "    git-profile current         # Show current git profile"
  echo "    git-profile switch work     # Switch to work git profile"
  echo "    git whoami                  # Show current git user"
}

list_profiles() {
  echo -e "${BLUE}Available profiles:${NC}"

  if [[ ! -f $VARS_FILE || ! -f $PROFILES_FILE ]]; then
    echo -e "${RED}Error:${NC} vars.nix or profiles.nix file not found"
    return 1
  fi

  for profile in "${PROFILES[@]}"; do
    echo -e "\n${GREEN}$profile:${NC}"

    if command -v nix >/dev/null 2>&1; then
      # Show default git profile from vars.nix (shared across all profiles)
      local default_git_profile
      default_git_profile=$(nix eval --raw --file "$VARS_FILE" "gitProfiles.default" 2>/dev/null || echo "personal")
      echo "  Default Git Profile: $default_git_profile"

      # Show profile-specific system configuration
      local username hostname
      username=$(nix eval --raw --file "$PROFILES_FILE" "$profile.user.username" 2>/dev/null || echo "N/A")
      hostname=$(nix eval --raw --file "$PROFILES_FILE" "$profile.user.hostname" 2>/dev/null || echo "N/A")
      echo "  System Config:"
      echo "    Username: $username"
      echo "    Hostname: $hostname"

      # Show key capabilities (simplified)
      echo "  Key Capabilities:"
      local wsl desktop power
      wsl=$(nix eval --raw --file "$PROFILES_FILE" "$profile.capabilities.wsl" 2>/dev/null || echo "false")
      desktop=$(nix eval --raw --file "$PROFILES_FILE" "$profile.capabilities.desktop" 2>/dev/null || echo "false")
      power=$(nix eval --raw --file "$PROFILES_FILE" "$profile.capabilities.power" 2>/dev/null || echo "false")
      echo "    WSL: $wsl, Desktop: $desktop, Power Management: $power"
    else
      echo "  (Install nix to see detailed configuration)"
    fi
  done

  echo -e "\n${YELLOW}Note:${NC} Git profiles are shared across all system profiles"
  echo -e "       Use ${BLUE}git-profile${NC} command to switch between git profiles within an environment"
}

get_current_profile() {
  if [[ -f $FLAKE_FILE ]]; then
    local current
    current=$(grep -o 'profile = "[^"]*"' "$FLAKE_FILE" 2>/dev/null | sed 's/profile = "\(.*\)"/\1/' 2>/dev/null || echo "unknown")
    if [[ -z $current ]]; then
      current="unknown"
    fi
    echo "$current"
  else
    echo "unknown"
  fi
}

show_current_profile() {
  local current
  current=$(get_current_profile)
  echo -e "${BLUE}Current profile:${NC} ${GREEN}$current${NC}"

  if [[ -f $VARS_FILE && -f $PROFILES_FILE && $current != "unknown" ]] && command -v nix >/dev/null 2>&1; then
    echo -e "\n${BLUE}Current configuration:${NC}"

    # Show shared git configuration
    local default_git_profile
    default_git_profile=$(nix eval --raw --file "$VARS_FILE" "gitProfiles.default" 2>/dev/null || echo "personal")
    echo -e "  ${YELLOW}Default Git Profile (shared):${NC} $default_git_profile"

    local current_git_profile="${GIT_PROFILE:-$default_git_profile}"
    echo -e "  ${YELLOW}Active Git Profile:${NC} $current_git_profile"

    # Show git user information
    local git_config
    git_config=$(nix eval --json --file "$VARS_FILE" "gitProfiles.$current_git_profile" 2>/dev/null || echo "{}")
    if [[ $git_config != "{}" ]]; then
      local git_user git_email
      git_user=$(echo "$git_config" | nix-shell -p jq --run 'jq -r .userName' 2>/dev/null || echo "N/A")
      git_email=$(echo "$git_config" | nix-shell -p jq --run 'jq -r .userEmail' 2>/dev/null || echo "N/A")
      echo -e "    ${BLUE}User:${NC} $git_user <$git_email>"
    fi

    # Show profile-specific system configuration
    local user_config
    user_config=$(nix eval --json --file "$PROFILES_FILE" "$current.user" 2>/dev/null || echo "{}")
    if [[ $user_config != "{}" ]]; then
      echo -e "  ${YELLOW}System Configuration:${NC}"
      local username hostname
      username=$(echo "$user_config" | nix-shell -p jq --run 'jq -r .username' 2>/dev/null || echo "N/A")
      hostname=$(echo "$user_config" | nix-shell -p jq --run 'jq -r .hostname' 2>/dev/null || echo "N/A")
      echo -e "    ${BLUE}Username:${NC} $username"
      echo -e "    ${BLUE}Hostname:${NC} $hostname"
    fi

    echo -e "\n${YELLOW}Git Profile Commands:${NC}"
    echo -e "  ${BLUE}git-profile list${NC}       # List available git profiles"
    echo -e "  ${BLUE}git-profile current${NC}    # Show current git profile"
    echo -e "  ${BLUE}git-profile switch desktop${NC} # Switch to desktop git profile"
  fi
}

validate_profile() {
  local profile="$1"
  for valid_profile in "${PROFILES[@]}"; do
    if [[ $profile == "$valid_profile" ]]; then
      return 0
    fi
  done
  return 1
}

show_profile_diff() {
  local new_profile="$1"
  local current_profile
  current_profile=$(get_current_profile)

  echo -e "${BLUE}Profile comparison:${NC}"
  echo -e "  Current: ${GREEN}$current_profile${NC}"
  echo -e "  New:     ${GREEN}$new_profile${NC}"

  if [[ -f $VARS_FILE && -f $PROFILES_FILE ]] && command -v nix >/dev/null 2>&1; then
    echo -e "\n${BLUE}Configuration changes:${NC}"

    echo -e "${YELLOW}Shared Git Configuration:${NC}"
    local shared_default_git
    shared_default_git=$(nix eval --raw --file "$VARS_FILE" "gitProfiles.default" 2>/dev/null || echo "personal")
    echo "  All profiles share the same git profiles with default: $shared_default_git"

    echo -e "\n${YELLOW}System Configuration Changes:${NC}"

    # Current system config
    local current_user
    current_user=$(nix eval --json --file "$PROFILES_FILE" "$current_profile.user" 2>/dev/null || echo "{}")
    if [[ $current_user != "{}" ]]; then
      local current_username current_hostname
      current_username=$(echo "$current_user" | nix-shell -p jq --run 'jq -r .username' 2>/dev/null || echo "N/A")
      current_hostname=$(echo "$current_user" | nix-shell -p jq --run 'jq -r .hostname' 2>/dev/null || echo "N/A")
      echo "  Current: $current_username@$current_hostname"
    fi

    # New system config
    local new_user
    new_user=$(nix eval --json --file "$PROFILES_FILE" "$new_profile.user" 2>/dev/null || echo "{}")
    if [[ $new_user != "{}" ]]; then
      local new_username new_hostname
      new_username=$(echo "$new_user" | nix-shell -p jq --run 'jq -r .username' 2>/dev/null || echo "N/A")
      new_hostname=$(echo "$new_user" | nix-shell -p jq --run 'jq -r .hostname' 2>/dev/null || echo "N/A")
      echo "  New:     $new_username@$new_hostname"
    fi

    # Show capability changes
    local new_capabilities
    new_capabilities=$(nix eval --json --file "$PROFILES_FILE" "$new_profile.capabilities" 2>/dev/null || echo "{}")
    if [[ $new_capabilities != "{}" ]]; then
      echo -e "\n${YELLOW}New Profile Capabilities:${NC}"
      echo "$new_capabilities" | nix-shell -p jq --run 'jq -r "to_entries[] | \"  \" + .key + \": \" + (.value | tostring)"' 2>/dev/null || echo "  (details require jq)"
    fi
  fi
}

switch_profile() {
  local new_profile="$1"
  local dry_run="${2:-false}"
  local rebuild="${3:-false}"

  if ! validate_profile "$new_profile"; then
    echo -e "${RED}Error:${NC} Invalid profile '$new_profile'" >&2
    echo -e "Valid profiles: ${PROFILES[*]}" >&2
    return 1
  fi

  local current_profile
  current_profile=$(get_current_profile)

  if [[ $current_profile == "$new_profile" ]]; then
    echo -e "${YELLOW}Already using profile:${NC} $new_profile"
    return 0
  fi

  if [[ $dry_run == "true" ]]; then
    show_profile_diff "$new_profile"
    echo -e "\n${YELLOW}Dry run - no changes made${NC}"
    return 0
  fi

  echo -e "${BLUE}Switching profile from${NC} ${GREEN}$current_profile${NC} ${BLUE}to${NC} ${GREEN}$new_profile${NC}"

  cp "$FLAKE_FILE" "$FLAKE_FILE.backup.$(date +%s)"

  sed -i "s/profile = \"$current_profile\"/profile = \"$new_profile\"/" "$FLAKE_FILE"

  local updated_profile
  updated_profile=$(get_current_profile)

  if [[ $updated_profile != "$new_profile" ]]; then
    echo -e "${RED}Error:${NC} Failed to update profile in flake.nix" >&2
    # Restore backup
    mv "$FLAKE_FILE.backup."* "$FLAKE_FILE" 2>/dev/null || true
    return 1
  fi

  echo -e "${GREEN}✓${NC} Profile updated successfully"

  if command -v nix >/dev/null 2>&1 && nix flake check --quiet 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Configuration validation passed"
  else
    echo -e "${YELLOW}⚠${NC} Configuration validation failed or nix not available"
    echo -e "  Run ${BLUE}nix flake check${NC} to see details"
  fi

  if [[ $rebuild == "true" ]]; then
    echo -e "\n${BLUE}Rebuilding system with new profile...${NC}"
    if sudo nixos-rebuild switch --flake "$FLAKE_DIR" 2>/dev/null; then
      echo -e "${GREEN}✓${NC} System rebuild completed successfully"
    else
      echo -e "${RED}✗${NC} System rebuild failed"
      echo -e "  You may need to run the rebuild manually"
      return 1
    fi
  else
    echo -e "\n${YELLOW}Next steps:${NC}"
    echo -e "  ${BLUE}direnv reload${NC}                           # For development environment"
    echo -e "  ${BLUE}sudo nixos-rebuild switch --flake .${NC}     # For system configuration"
  fi

  find "$FLAKE_DIR" -name "flake.nix.backup.*" -type f | sort -r | tail -n +4 | xargs rm -f 2>/dev/null || true
}

main() {
  local profile=""
  local dry_run=false
  local rebuild=false
  local show_current=false
  local list_only=false

  while [[ $# -gt 0 ]]; do
    case $1 in
    -h | --help)
      show_usage
      exit 0
      ;;
    -l | --list)
      list_only=true
      shift
      ;;
    -c | --current)
      show_current=true
      shift
      ;;
    -d | --dry-run)
      dry_run=true
      shift
      ;;
    --rebuild)
      rebuild=true
      shift
      ;;
    wsl | workstation | mobile)
      profile="$1"
      shift
      ;;
    *)
      echo -e "${RED}Error:${NC} Unknown option '$1'" >&2
      echo "Use --help for usage information" >&2
      exit 1
      ;;
    esac
  done

  if [[ ! -f $FLAKE_FILE || ! -f $VARS_FILE || ! -f $PROFILES_FILE ]]; then
    echo -e "${RED}Error:${NC} This script must be run from the nixos-wsl-dotfiles directory" >&2
    echo "Expected files: flake.nix, vars.nix, profiles.nix" >&2
    exit 1
  fi

  if [[ $list_only == "true" ]]; then
    list_profiles
    exit 0
  fi

  if [[ $show_current == "true" ]]; then
    show_current_profile
    exit 0
  fi

  if [[ -z $profile ]]; then
    show_current_profile
    echo ""
    show_usage
    exit 0
  fi

  switch_profile "$profile" "$dry_run" "$rebuild"
}

if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  main "$@"
fi
