#!/usr/bin/env bash

#===============================================================================
# NixOS ProDot Auto-Setup Script
#===============================================================================
#
# DESCRIPTION:
#   This script automates the complete setup process for a NixOS configuration.
#   It supports three profiles: wsl (minimal), workstation (full desktop), and
#   mobile (laptop configuration). The script handles repository cloning, user
#   configuration collection, SSH/GPG key generation, and system configuration.
#
# USAGE:
#   # Direct execution:
#   curl -L https://raw.githubusercontent.com/albedosehen/nixos-prodot/main/scripts/auto-setup.sh | bash
#
#   # Local execution:
#   ./scripts/auto-setup.sh
#
#   # With debug logging:
#   DEBUG=1 ./scripts/auto-setup.sh
#
#   # With custom repository:
#   NIXOS_PRODOT_REPO_URL="https://github.com/yourfork/nixos-prodot.git" ./scripts/auto-setup.sh
#
# ENVIRONMENT VARIABLES:
#   DEBUG                    - Enable debug logging (0/1, default: 0)
#   NIXOS_PRODOT_REPO_URL   - Custom repository URL (default: official repo)
#   NIXOS_PRODOT_CONFIG_DIR - Custom config directory (default: ~/.nixos-prodot)
#   NIXOS_PRODOT_SSH_DIR    - Custom SSH directory (default: ~/.ssh)
#   NIXOS_PRODOT_SKIP_APPLY - Skip configuration application (0/1, default: 0)
#
# REQUIREMENTS:
#   - NixOS with flakes enabled
#   - curl, git, nix commands available
#   - Internet connection for repository cloning
#
# PHASES IMPLEMENTED:
#   Phase 1: Security fixes and input validation
#   Phase 2: Robustness improvements and error handling
#   Phase 3: Code quality and maintainability improvements
#
# AUTHORS:
#   NixOS ProDot Contributors
#
# LICENSE:
#   See LICENSE file in the repository
#
#===============================================================================

set -euo pipefail

#===============================================================================
# GLOBAL CONFIGURATION AND CONSTANTS
#===============================================================================

# Color definitions for output formatting
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Configuration variables (configurable via environment)
readonly REPO_URL="${NIXOS_PRODOT_REPO_URL:-https://github.com/albedosehen/nixos-prodot.git}"
readonly CONFIG_DIR="${NIXOS_PRODOT_CONFIG_DIR:-$HOME/.nixos-prodot}"
readonly SSH_DIR="${NIXOS_PRODOT_SSH_DIR:-$HOME/.ssh}"
readonly SKIP_APPLY="${NIXOS_PRODOT_SKIP_APPLY:-0}"

# Progress tracking
STEP=0
readonly TOTAL_STEPS=12

# Debug logging (controlled by DEBUG environment variable)
readonly DEBUG="${DEBUG:-0}"

# Error handling configuration
SCRIPT_EXIT_CODE=0

#===============================================================================
# UTILITY FUNCTIONS - OUTPUT AND FORMATTING
#===============================================================================

##
# Print the script header with branding
# Globals:
#   PURPLE, NC (color constants)
# Arguments:
#   None
# Returns:
#   None
##
print_header() {
  echo -e "\n${PURPLE}==============================${NC}"
  echo -e "${PURPLE}  NixOS Auto-Setup Script  ${NC}"
  echo -e "${PURPLE}==============================${NC}\n"
}

##
# Print a numbered step in the setup process
# Globals:
#   STEP, TOTAL_STEPS, BLUE, NC
# Arguments:
#   $1 - Step description
# Returns:
#   None
##
print_step() {
  STEP=$((STEP + 1))
  echo -e "\n${BLUE}[${STEP}/${TOTAL_STEPS}] $1${NC}"
}

##
# Print a success message with green checkmark
# Globals:
#   GREEN, NC
# Arguments:
#   $1 - Success message
# Returns:
#   None
##
print_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

##
# Print a warning message with yellow warning icon
# Globals:
#   YELLOW, NC
# Arguments:
#   $1 - Warning message
# Returns:
#   None
##
print_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

##
# Print an error message with red X icon
# Globals:
#   RED, NC
# Arguments:
#   $1 - Error message
# Returns:
#   None
##
print_error() {
  echo -e "${RED}❌ $1${NC}"
}

##
# Print an informational message with cyan info icon
# Globals:
#   CYAN, NC
# Arguments:
#   $1 - Info message
# Returns:
#   None
##
print_info() {
  echo -e "${CYAN}ℹ️  $1${NC}"
}

##
# Print a debug message if DEBUG mode is enabled
# Globals:
#   DEBUG, PURPLE, NC
# Arguments:
#   $1 - Debug message
# Returns:
#   None
##
print_debug() {
  if [[ $DEBUG == "1" ]]; then
    echo -e "${PURPLE}[DEBUG] $1${NC}" >&2
  fi
}

#===============================================================================
# ERROR HANDLING FUNCTIONS
#===============================================================================

##
# Centralized error handling function with enhanced debugging
# Globals:
#   SCRIPT_EXIT_CODE, FUNCNAME
# Arguments:
#   $1 - Exit code (default: 1)
#   $2 - Error message (default: "An error occurred")
#   $3 - Line number (default: "unknown")
# Returns:
#   Exit code specified in $1
##
handle_error() {
  local exit_code="${1:-1}"
  local error_msg="${2:-"An error occurred"}"
  local line_no="${3:-"unknown"}"

  print_error "$error_msg (line: $line_no)"
  print_debug "Error occurred in function: ${FUNCNAME[2]:-main}"
  print_debug "Call stack: ${FUNCNAME[*]}"

  SCRIPT_EXIT_CODE="$exit_code"
  return "$exit_code"
}

##
# Safe exit function that ensures proper cleanup
# Globals:
#   SCRIPT_EXIT_CODE
# Arguments:
#   $1 - Exit code (default: SCRIPT_EXIT_CODE)
# Returns:
#   Exits with specified code
##
safe_exit() {
  local exit_code="${1:-$SCRIPT_EXIT_CODE}"
  print_debug "Exiting with code: $exit_code"
  exit "$exit_code"
}

#===============================================================================
# INPUT VALIDATION FUNCTIONS
#===============================================================================

##
# Validate username according to system requirements
# Arguments:
#   $1 - Username to validate
# Returns:
#   0 if valid, 1 if invalid
# Validation rules:
#   - Length: 1-32 characters
#   - Characters: alphanumeric, underscore, hyphen
#   - Cannot start with hyphen
##
validate_username() {
  local username="$1"
  print_debug "Validating username: $username"

  # Check length (1-32 characters)
  if [[ ${#username} -lt 1 || ${#username} -gt 32 ]]; then
    return 1
  fi

  # Check for valid characters (alphanumeric, underscore, hyphen)
  if [[ ! $username =~ ^[a-zA-Z0-9_-]+$ ]]; then
    return 1
  fi

  # Cannot start with hyphen
  if [[ $username =~ ^- ]]; then
    return 1
  fi

  return 0
}

##
# Validate hostname according to RFC standards
# Arguments:
#   $1 - Hostname to validate
# Returns:
#   0 if valid, 1 if invalid
# Validation rules:
#   - Length: 1-63 characters
#   - Characters: alphanumeric and hyphen
#   - Cannot start or end with hyphen
##
validate_hostname() {
  local hostname="$1"
  print_debug "Validating hostname: $hostname"

  # Check length (1-63 characters)
  if [[ ${#hostname} -lt 1 || ${#hostname} -gt 63 ]]; then
    return 1
  fi

  # Check for valid characters (alphanumeric and hyphen)
  if [[ ! $hostname =~ ^[a-zA-Z0-9-]+$ ]]; then
    return 1
  fi

  # Cannot start or end with hyphen
  if [[ $hostname =~ ^- || $hostname =~ -$ ]]; then
    return 1
  fi

  return 0
}

##
# Validate email address format
# Arguments:
#   $1 - Email address to validate
# Returns:
#   0 if valid, 1 if invalid
# Validation rules:
#   - Basic RFC-compliant email format
#   - Must contain @ symbol with valid local and domain parts
##
validate_email() {
  local email="$1"
  print_debug "Validating email: $email"

  # Basic email validation regex
  if [[ $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    return 0
  fi

  return 1
}

##
# Validate NixOS profile selection
# Arguments:
#   $1 - Profile name to validate
# Returns:
#   0 if valid, 1 if invalid
# Valid profiles:
#   - wsl: Minimal environment without desktop
#   - workstation: Full desktop workstation
#   - mobile: Laptop/mobile configuration
##
validate_profile() {
  local profile="$1"
  print_debug "Validating profile: $profile"

  case "$profile" in
  wsl | workstation | mobile)
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}

##
# Validate Git provider selection
# Arguments:
#   $1 - Git provider name to validate
# Returns:
#   0 if valid, 1 if invalid
# Valid providers:
#   - github: GitHub.com
#   - bitbucket: Bitbucket.org
#   - gitlab: GitLab.com
##
validate_git_provider() {
  local provider="$1"
  print_debug "Validating git provider: $provider"

  case "$provider" in
  github | bitbucket | gitlab)
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}

#===============================================================================
# USER INTERACTION FUNCTIONS
#===============================================================================

##
# Prompt user for input with optional default value
# Arguments:
#   $1 - Prompt message
#   $2 - Default value (optional)
# Returns:
#   User input or default value via stdout
##
prompt_user() {
  local prompt="$1"
  local default="$2"
  local response

  if [[ -n $default ]]; then
    echo -e "${CYAN}$prompt [${default}]: ${NC}"
  else
    echo -e "${CYAN}$prompt: ${NC}"
  fi

  read -r response
  echo "${response:-$default}"
}

##
# Prompt user for yes/no confirmation
# Arguments:
#   $1 - Prompt message
#   $2 - Default value ("y" or "n")
# Returns:
#   0 for yes, 1 for no
##
prompt_yes_no() {
  local prompt="$1"
  local default="$2"
  local response

  while true; do
    if [[ $default == "y" ]]; then
      echo -e "${CYAN}$prompt [Y/n]: ${NC}"
    else
      echo -e "${CYAN}$prompt [y/N]: ${NC}"
    fi

    read -r response
    response="${response:-$default}"

    case "$response" in
    [Yy] | [Yy][Ee][Ss]) return 0 ;;
    [Nn] | [Nn][Oo]) return 1 ;;
    *) echo -e "${RED}Please answer yes or no.${NC}" ;;
    esac
  done
}

##
# Check if a command is available in PATH
# Arguments:
#   $1 - Command name to check
# Returns:
#   0 if available, 1 if not available
##
check_command() {
  if command -v "$1" >/dev/null 2>&1; then
    print_success "$1 is available"
    return 0
  else
    print_error "$1 is not available"
    return 1
  fi
}

#===============================================================================
# SYSTEM VERIFICATION FUNCTIONS
#===============================================================================
##
# Check system prerequisites and required tools
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   Exits script if prerequisites are not met
# Required tools:
#   - curl: For downloading files
#   - git: For repository operations
#   - nix: For NixOS operations
##
check_prerequisites() {
  print_step "Checking prerequisites"

  local missing_tools=()

  # Check for required tools
  for tool in curl git nix; do
    if ! check_command "$tool"; then
      missing_tools+=("$tool")
    fi
  done

  if [[ ${#missing_tools[@]} -gt 0 ]]; then
    print_error "Missing required tools: ${missing_tools[*]}"
    print_info "Please install the missing tools and run this script again."
    handle_error 1 "Missing required tools" "$LINENO"
    safe_exit 1
  fi

  # Check if we're in WSL (optional detection for environment-specific optimizations)
  if [[ -f /proc/version ]] && grep -qi microsoft /proc/version; then
    print_info "WSL environment detected"
  fi

  print_success "All prerequisites met"
}

##
# Verify Nix configuration and flakes support
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   Exits script if Nix is not properly configured
# Checks:
#   - Nix installation and version
#   - Flakes experimental feature enabled
#   - Optional direnv availability
##
verify_nix_config() {
  print_step "Verifying Nix configuration"

  # Check if Nix flakes are enabled
  if ! nix --version >/dev/null 2>&1; then
    handle_error 1 "Nix is not properly configured" "$LINENO"
    safe_exit 1
  fi

  # Check for experimental features
  if ! nix flake --help >/dev/null 2>&1; then
    print_error "Nix flakes are not enabled"
    print_info "Please enable flakes by adding 'experimental-features = nix-command flakes' to your nix.conf"
    handle_error 1 "Nix flakes not enabled" "$LINENO"
    safe_exit 1
  fi

  # Check for direnv if available
  if check_command "direnv"; then
    print_success "direnv is available for development shell"
  else
    print_warning "direnv not found - development shell will need manual activation"
  fi

  print_success "Nix configuration verified"
}

#===============================================================================
# SETUP AND CONFIGURATION FUNCTIONS
#===============================================================================

setup_development_shell() {
  print_step "Setting up development shell"

  # If we're already in the config directory, use it
  if [[ -f "flake.nix" && -f "vars.nix" ]]; then
    print_info "Already in configuration directory"
    return 0
  fi

  # If config directory exists, cd into it
  if [[ -d $CONFIG_DIR ]]; then
    cd "$CONFIG_DIR"
    print_info "Using existing configuration directory: $CONFIG_DIR"
    return 0
  fi

  print_info "Development shell will be set up after repository clone"
}

check_existing_config() {
  print_step "Checking for existing configuration"

  if [[ -d $CONFIG_DIR ]]; then
    print_warning "Existing configuration found at $CONFIG_DIR"

    if prompt_yes_no "Do you want to backup and overwrite the existing configuration?" "n"; then
      local backup_dir
      backup_dir="${CONFIG_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
      print_info "Backing up existing configuration to $backup_dir"
      mv "$CONFIG_DIR" "$backup_dir"
      print_success "Backup created at $backup_dir"
      return 0
    else
      print_info "Using existing configuration directory"
      cd "$CONFIG_DIR"
      return 1
    fi
  fi

  return 0
}

clone_repository() {
  print_step "Cloning repository"

  # Skip if we're already in the right directory
  if [[ -f "flake.nix" && -f "vars.nix" ]]; then
    print_info "Already in configuration directory"
    return 0
  fi

  # Skip if we're using existing config
  if [[ -d $CONFIG_DIR ]]; then
    cd "$CONFIG_DIR"
    print_info "Using existing configuration"
    return 0
  fi

  if prompt_yes_no "Do you have a fork of the repository?" "n"; then
    local fork_url
    fork_url=$(prompt_user "Enter your fork URL" "")
    if [[ -n $fork_url ]]; then
      REPO_URL="$fork_url"
    fi
  fi

  print_info "Cloning from $REPO_URL"
  if ! git clone "$REPO_URL" "$CONFIG_DIR"; then
    handle_error 1 "Failed to clone repository from $REPO_URL" "$LINENO"
    safe_exit 1
  fi
  cd "$CONFIG_DIR"

  print_success "Repository cloned successfully"
}

collect_user_config() {
  print_step "Collecting user configuration"

  echo -e "\n${PURPLE}User Configuration${NC}"
  echo -e "${PURPLE}==================${NC}"

  # Collect and validate username
  while true; do
    USERNAME=$(prompt_user "Enter username" "nixos")
    if validate_username "$USERNAME"; then
      print_debug "Username validation passed: $USERNAME"
      break
    else
      print_error "Invalid username '$USERNAME'. Must be 1-32 characters, alphanumeric with underscore/hyphen, cannot start with hyphen."
    fi
  done

  # Collect and validate hostname
  while true; do
    HOSTNAME=$(prompt_user "Enter hostname" "nixos")
    if validate_hostname "$HOSTNAME"; then
      print_debug "Hostname validation passed: $HOSTNAME"
      break
    else
      print_error "Invalid hostname '$HOSTNAME'. Must be 1-63 characters, alphanumeric with hyphen, cannot start/end with hyphen."
    fi
  done

  echo -e "\n${PURPLE}Available profiles:${NC}"
  echo -e "  ${GREEN}wsl${NC}        - Minimal environment (no desktop)"
  echo -e "  ${GREEN}workstation${NC} - Full desktop workstation"
  echo -e "  ${GREEN}mobile${NC}      - Laptop/mobile configuration"

  # Collect and validate profile
  while true; do
    PROFILE=$(prompt_user "Select profile (wsl/workstation/mobile)" "wsl")
    if validate_profile "$PROFILE"; then
      print_debug "Profile validation passed: $PROFILE"
      break
    else
      print_error "Invalid profile '$PROFILE'. Must be one of: wsl, workstation, mobile"
    fi
  done

  print_success "User configuration collected"
}

collect_git_config() {
  print_step "Collecting Git configuration"

  echo -e "\n${PURPLE}Personal Git Configuration${NC}"
  echo -e "${PURPLE}===========================${NC}"

  # Collect and validate git provider
  while true; do
    GIT_PROVIDER=$(prompt_user "Git provider (github/bitbucket/gitlab)" "github")
    if validate_git_provider "$GIT_PROVIDER"; then
      print_debug "Git provider validation passed: $GIT_PROVIDER"
      break
    else
      print_error "Invalid git provider '$GIT_PROVIDER'. Must be one of: github, bitbucket, gitlab"
    fi
  done

  # Collect full name (allow empty for now, but warn)
  GIT_PERSONAL_NAME=$(prompt_user "Full name" "")
  if [[ -z $GIT_PERSONAL_NAME ]]; then
    print_warning "Full name is empty. This may affect Git commit attribution."
  fi

  # Collect and validate email
  while true; do
    GIT_PERSONAL_EMAIL=$(prompt_user "Email address" "")
    if [[ -n $GIT_PERSONAL_EMAIL ]] && validate_email "$GIT_PERSONAL_EMAIL"; then
      print_debug "Email validation passed: $GIT_PERSONAL_EMAIL"
      break
    else
      print_error "Invalid email address '$GIT_PERSONAL_EMAIL'. Please enter a valid email."
    fi
  done

  # SSH key generation
  if prompt_yes_no "Generate SSH key for Git?" "y"; then
    GENERATE_SSH="true"
    SSH_KEY_PATH="$SSH_DIR/id_rsa_${GIT_PROVIDER}"
  else
    GENERATE_SSH="false"
  fi

  # GPG key generation
  if prompt_yes_no "Generate GPG key for commit signing?" "n"; then
    GENERATE_GPG="true"
  else
    GENERATE_GPG="false"
  fi

  # Work Git configuration
  echo -e "\n${PURPLE}Work Git Configuration (Optional)${NC}"
  echo -e "${PURPLE}==================================${NC}"

  if prompt_yes_no "Configure work Git profile?" "n"; then
    SETUP_WORK_GIT="true"
    GIT_WORK_NAME=$(prompt_user "Work full name" "")
    GIT_WORK_EMAIL=$(prompt_user "Work email address" "")

    if prompt_yes_no "Generate separate SSH key for work?" "y"; then
      GENERATE_WORK_SSH="true"
      WORK_SSH_KEY_PATH="$SSH_DIR/id_rsa_work"
    else
      GENERATE_WORK_SSH="false"
    fi
  else
    SETUP_WORK_GIT="false"
  fi

  print_success "Git configuration collected"
}

generate_ssh_keys() {
  if [[ $GENERATE_SSH == "true" ]]; then
    print_step "Generating SSH keys"

    # Use safer directory creation with atomic operation
    if ! mkdir -p "$SSH_DIR" 2>/dev/null; then
      handle_error 1 "Failed to create SSH directory" "$LINENO"
      safe_exit 1
    fi
    chmod 700 "$SSH_DIR"

    if [[ ! -f $SSH_KEY_PATH ]]; then
      print_info "Generating personal SSH key: $SSH_KEY_PATH"
      if ! ssh-keygen -t ed25519 -C "$GIT_PERSONAL_EMAIL" -f "$SSH_KEY_PATH" -N ""; then
        handle_error 1 "Failed to generate personal SSH key" "$LINENO"
        safe_exit 1
      fi
      print_success "Personal SSH key generated"

      print_info "Add this public key to your $GIT_PROVIDER account:"
      echo -e "${YELLOW}$(cat "${SSH_KEY_PATH}.pub")${NC}"
    else
      print_warning "SSH key already exists: $SSH_KEY_PATH"
    fi

    if [[ $GENERATE_WORK_SSH == "true" && ! -f $WORK_SSH_KEY_PATH ]]; then
      print_info "Generating work SSH key: $WORK_SSH_KEY_PATH"
      if ! ssh-keygen -t ed25519 -C "$GIT_WORK_EMAIL" -f "$WORK_SSH_KEY_PATH" -N ""; then
        handle_error 1 "Failed to generate work SSH key" "$LINENO"
        safe_exit 1
      fi
      print_success "Work SSH key generated"

      print_info "Add this public key to your work Git provider:"
      echo -e "${YELLOW}$(cat "${WORK_SSH_KEY_PATH}.pub")${NC}"
    fi
  fi
}

generate_gpg_keys() {
  if [[ $GENERATE_GPG == "true" ]]; then
    print_step "Generating GPG keys"

    if command -v gpg >/dev/null 2>&1; then
      print_info "Generating GPG key for $GIT_PERSONAL_EMAIL"

      # Create secure temporary file for GPG batch operations
      local gpg_batch_file
      if ! gpg_batch_file=$(mktemp); then
        handle_error 1 "Failed to create secure temporary file for GPG operations" "$LINENO"
        safe_exit 1
      fi

      # Ensure cleanup of temporary file
      trap 'rm -f "$gpg_batch_file"' EXIT

      cat >"$gpg_batch_file" <<EOF
%echo Generating GPG key
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: $GIT_PERSONAL_NAME
Name-Email: $GIT_PERSONAL_EMAIL
Expire-Date: 0
%commit
%echo Done
EOF

      if ! gpg --batch --generate-key "$gpg_batch_file"; then
        print_error "Failed to generate GPG key"
        rm -f "$gpg_batch_file"
        handle_error 1 "Failed to generate GPG key" "$LINENO"
        safe_exit 1
      fi
      rm -f "$gpg_batch_file"

      # Get the key ID
      GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format LONG "$GIT_PERSONAL_EMAIL" | grep sec | awk '{print $2}' | cut -d'/' -f2)

      if [[ -n $GPG_KEY_ID ]]; then
        print_success "GPG key generated with ID: $GPG_KEY_ID"
        print_info "Add this GPG key to your $GIT_PROVIDER account:"
        gpg --armor --export "$GPG_KEY_ID"
      fi
    else
      print_warning "GPG not available, skipping GPG key generation"
      GENERATE_GPG="false"
    fi
  fi
}

update_configuration() {
  print_step "Updating configuration files"

  # Update vars.nix
  print_info "Updating vars.nix"
  print_debug "Starting atomic vars.nix update"

  # Create safe backup with timestamp to avoid overwriting existing backups
  local backup_file
  backup_file="vars.nix.backup.$(date +%Y%m%d_%H%M%S)"
  if ! cp vars.nix "$backup_file"; then
    handle_error 1 "Failed to create backup of vars.nix" "$LINENO"
    safe_exit 1
  fi
  print_info "Created backup: $backup_file"

  # Create temporary file for atomic operation
  local temp_vars_file
  if ! temp_vars_file=$(mktemp "${PWD}/vars.nix.tmp.XXXXXX"); then
    handle_error 1 "Failed to create temporary file for vars.nix" "$LINENO"
    safe_exit 1
  fi
  print_debug "Created temporary file: $temp_vars_file"

  # Ensure cleanup of temporary file on exit
  trap 'rm -f "$temp_vars_file"' EXIT

  # Build the new vars.nix content in temporary file
  cat >"$temp_vars_file" <<EOF
{
  ## Selected profile
  # Options: wsl, workstation, mobile or create your own
  selected-profile = "$PROFILE";

  ## User configuration
  user = {
    username = "$USERNAME";
    hostname = "$HOSTNAME";
  };

  ## Git Profiles
  gitProfiles = {
    default = "personal";

    personal = {
      userName = "$GIT_PERSONAL_NAME";
      userEmail = "$GIT_PERSONAL_EMAIL";
EOF

  # Add GPG signing key if generated
  if [[ $GENERATE_GPG == "true" && -n ${GPG_KEY_ID:-} ]]; then
    echo "      signingKey = \"$GPG_KEY_ID\";" >>"$temp_vars_file"
  else
    echo "      signingKey = null;" >>"$temp_vars_file"
  fi

  # Add SSH configuration if generated
  if [[ $GENERATE_SSH == "true" ]]; then
    cat >>"$temp_vars_file" <<EOF
      extraConfig = {
        core.sshCommand = "ssh -i $SSH_KEY_PATH -o IdentitiesOnly=yes";
      };
EOF
  else
    echo "      extraConfig = {};" >>"$temp_vars_file"
  fi

  echo "    };" >>"$temp_vars_file"

  # Add work configuration if requested
  if [[ $SETUP_WORK_GIT == "true" ]]; then
    cat >>"$temp_vars_file" <<EOF

    work = {
      userName = "$GIT_WORK_NAME";
      userEmail = "$GIT_WORK_EMAIL";
      signingKey = null;
EOF

    if [[ $GENERATE_WORK_SSH == "true" ]]; then
      cat >>"$temp_vars_file" <<EOF
      extraConfig = {
        core.sshCommand = "ssh -i $WORK_SSH_KEY_PATH -o IdentitiesOnly=yes";
      };
EOF
    else
      echo "      extraConfig = {};" >>"$temp_vars_file"
    fi

    echo "    };" >>"$temp_vars_file"
  fi

  echo "  };" >>"$temp_vars_file"
  echo "}" >>"$temp_vars_file"

  # Atomically move the temporary file to the final location
  if ! mv "$temp_vars_file" vars.nix; then
    handle_error 1 "Failed to atomically update vars.nix" "$LINENO"
    safe_exit 1
  fi
  print_debug "Atomic vars.nix update completed successfully"

  print_success "vars.nix updated"

  # Update justfile build commands to use the correct hostname
  print_info "Updating justfile for profile: $PROFILE"

  # Update justfile to use the correct hostname if it differs from the default
  if [[ $HOSTNAME != "nixos" ]]; then
    # Replace any default hostname references with the user's hostname
    # Sanitize hostname to prevent command injection
    local safe_hostname
    safe_hostname=$(printf '%s\n' "$HOSTNAME" | sed "s/[[\.*^$()+?{|]/\\\\&/g")

    if ! sed -i "s/nixos-wsl/$safe_hostname/g" justfile; then
      handle_error 1 "Failed to update justfile with hostname" "$LINENO"
      safe_exit 1
    fi
    if ! sed -i "s/nixos/$safe_hostname/g" justfile; then
      handle_error 1 "Failed to update justfile with hostname" "$LINENO"
      safe_exit 1
    fi
    print_success "justfile updated with hostname: $HOSTNAME"
  fi
}

commit_changes() {
  print_step "Committing configuration changes"

  # Configure git for the initial commit
  git config user.name "$GIT_PERSONAL_NAME"
  git config user.email "$GIT_PERSONAL_EMAIL"

  # Stage changes
  git add vars.nix justfile

  # Commit changes
  git commit -m "Initial setup for NixOS configuration

- Username: $USERNAME
- Hostname: $HOSTNAME
- Profile: $PROFILE
- Personal Git: $GIT_PERSONAL_NAME <$GIT_PERSONAL_EMAIL>
$(if [[ $SETUP_WORK_GIT == "true" ]]; then echo "- Work Git: $GIT_WORK_NAME <$GIT_WORK_EMAIL>"; fi)
$(if [[ $GENERATE_SSH == "true" ]]; then echo "- SSH key generated"; fi)
$(if [[ $GENERATE_GPG == "true" ]]; then echo "- GPG key generated"; fi)"

  print_success "Changes committed to git"
}

apply_configuration() {
  print_step "Applying NixOS configuration"

  # Check if configuration application should be skipped
  if [[ $SKIP_APPLY == "1" ]]; then
    print_warning "Skipping system rebuild (NIXOS_PRODOT_SKIP_APPLY=1)"
    print_info "You can apply the configuration later by running: just install"
    return 0
  fi

  print_info "This will rebuild your NixOS system with the new configuration"
  print_warning "This process may take several minutes..."

  if prompt_yes_no "Proceed with system rebuild?" "y"; then
    # Enter development shell and run install
    if command -v just >/dev/null 2>&1; then
      print_info "Running: just install"
      just install
    else
      print_info "Running: nix develop -c just install"
      nix develop -c just install
    fi

    print_success "NixOS configuration applied successfully"
  else
    print_warning "Skipping system rebuild"
    print_info "You can apply the configuration later by running: just install"
  fi
}

provide_final_instructions() {
  print_step "Setup complete!"

  echo -e "\n${GREEN}🎉 NixOS configuration setup completed successfully!${NC}\n"

  echo -e "${PURPLE}Next Steps:${NC}"
  echo -e "1. ${CYAN}Restart your system or reload the shell:${NC}"
  echo -e "   ${YELLOW}# For WSL: wsl -t <your-distro-name> && wsl -d <your-distro-name>${NC}"
  echo -e "   ${YELLOW}# For other systems: logout and login or restart${NC}"

  echo -e "\n2. ${CYAN}Apply home-manager configuration:${NC}"
  echo -e "   ${YELLOW}cd $CONFIG_DIR${NC}"
  echo -e "   ${YELLOW}just nhs${NC}"

  if [[ $GENERATE_SSH == "true" ]]; then
    echo -e "\n3. ${CYAN}Add SSH keys to your Git provider:${NC}"
    echo -e "   Personal: ${YELLOW}cat ${SSH_KEY_PATH}.pub${NC}"
    if [[ $GENERATE_WORK_SSH == "true" ]]; then
      echo -e "   Work: ${YELLOW}cat ${WORK_SSH_KEY_PATH}.pub${NC}"
    fi
  fi

  if [[ $GENERATE_GPG == "true" && -n ${GPG_KEY_ID:-} ]]; then
    echo -e "\n4. ${CYAN}Add GPG key to your Git provider:${NC}"
    echo -e "   ${YELLOW}gpg --armor --export $GPG_KEY_ID${NC}"
  fi

  echo -e "\n${PURPLE}Useful Commands:${NC}"
  echo -e "  ${YELLOW}just help${NC}     - Show available commands"
  echo -e "  ${YELLOW}just switch${NC}   - Apply configuration changes"
  echo -e "  ${YELLOW}just update${NC}   - Update and rebuild system"
  echo -e "  ${YELLOW}just dev${NC}      - Enter development shell"

  echo -e "\n${PURPLE}Configuration Location:${NC} ${CYAN}$CONFIG_DIR${NC}"
  echo -e "${PURPLE}Documentation:${NC} ${CYAN}https://github.com/albedosehen/nixos-prodot${NC}"

  echo -e "\n${GREEN}Happy NixOS-ing! 🚀${NC}\n"
}

#===============================================================================
# MAIN EXECUTION FUNCTION
#===============================================================================

##
# Main script execution function
# Orchestrates the complete NixOS setup process through all phases
# Globals:
#   All script configuration variables
# Arguments:
#   $@ - Command line arguments (currently unused)
# Returns:
#   Exits with appropriate code on completion or error
# Process:
#   1. Check prerequisites and Nix configuration
#   2. Handle existing configurations and clone repository
#   3. Collect user and Git configuration
#   4. Generate SSH/GPG keys as requested
#   5. Update configuration files
#   6. Commit changes and apply configuration
##
main() {
  print_header
  print_debug "Starting auto-setup script with DEBUG=$DEBUG"
  print_debug "Script arguments: $*"

  # Trap errors and provide helpful messages with enhanced debugging
  trap 'handle_error $? "Setup failed at step $STEP" "$LINENO"; safe_exit 1' ERR

  print_debug "Checking prerequisites..."
  check_prerequisites

  print_debug "Verifying Nix configuration..."
  verify_nix_config

  print_debug "Setting up development shell..."
  setup_development_shell

  print_debug "Checking existing configuration..."
  if check_existing_config; then
    print_debug "Cloning repository..."
    clone_repository
  fi

  print_debug "Collecting user configuration..."
  collect_user_config

  print_debug "Collecting Git configuration..."
  collect_git_config

  print_debug "Generating SSH keys..."
  generate_ssh_keys

  print_debug "Generating GPG keys..."
  generate_gpg_keys

  print_debug "Updating configuration files..."
  update_configuration

  print_debug "Committing changes..."
  commit_changes

  print_debug "Applying configuration..."
  apply_configuration

  print_debug "Providing final instructions..."
  provide_final_instructions

  print_debug "Auto-setup completed successfully"
}

# Run main function if script is executed directly
if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  main "$@"
fi
