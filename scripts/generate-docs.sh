#!/usr/bin/env bash

set -euo pipefail

# Script to generate documentation source files locally using templates
# This eliminates duplication with pkgs/docs.nix by using shared templates

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOCS_DIR="$PROJECT_ROOT/docs"
TEMPLATES_DIR="$PROJECT_ROOT/docs/templates"

# Template variables for static generation
TITLE="NixOS ProDot Documentation"
REPO_URL="https://github.com/albedosehen/nixos-prodot"
PROFILE_CONTENT=""  # Empty for static generation

echo "🔧 Generating docs from templates..."

# Check if templates directory exists
if [ ! -d "$TEMPLATES_DIR" ]; then
    echo "❌ Templates directory not found: $TEMPLATES_DIR"
    echo "   Please ensure the template files exist in docs/templates/"
    exit 1
fi

mkdir -p "$DOCS_DIR/src"

# Function to substitute template variables
substitute_template() {
    local template_file="$1"
    local output_file="$2"
    
    if [ ! -f "$template_file" ]; then
        echo "❌ Template file not found: $template_file"
        exit 1
    fi
    
    # Use sed to substitute template variables
    sed -e "s|{{TITLE}}|$TITLE|g" \
        -e "s|{{REPO_URL}}|$REPO_URL|g" \
        -e "s|{{PROFILE_CONTENT}}|$PROFILE_CONTENT|g" \
        "$template_file" > "$output_file"
}

# Generate files from templates
echo "📝 Generating SUMMARY.md..."
substitute_template "$TEMPLATES_DIR/SUMMARY.md.template" "$DOCS_DIR/src/SUMMARY.md"

echo "📝 Generating book.toml..."
substitute_template "$TEMPLATES_DIR/book.toml.template" "$DOCS_DIR/book.toml"

echo "📝 Generating introduction.md..."
substitute_template "$TEMPLATES_DIR/introduction.md.template" "$DOCS_DIR/src/introduction.md"

echo "📝 Generating profiles.md..."
substitute_template "$TEMPLATES_DIR/profiles.md.template" "$DOCS_DIR/src/profiles.md"

echo "📝 Generating installation.md..."
substitute_template "$TEMPLATES_DIR/installation.md.template" "$DOCS_DIR/src/installation.md"

echo "📝 Generating configuration.md..."
substitute_template "$TEMPLATES_DIR/configuration.md.template" "$DOCS_DIR/src/configuration.md"

echo "📝 Generating switching.md..."
substitute_template "$TEMPLATES_DIR/switching.md.template" "$DOCS_DIR/src/switching.md"

echo "📝 Generating git-management.md..."
substitute_template "$TEMPLATES_DIR/git-management.md.template" "$DOCS_DIR/src/git-management.md"

echo "📝 Generating modules.md..."
substitute_template "$TEMPLATES_DIR/modules.md.template" "$DOCS_DIR/src/modules.md"

echo "📝 Generating development.md..."
substitute_template "$TEMPLATES_DIR/development.md.template" "$DOCS_DIR/src/development.md"

echo "📝 Generating testing.md..."
substitute_template "$TEMPLATES_DIR/testing.md.template" "$DOCS_DIR/src/testing.md"

echo "📝 Generating contributing.md..."
substitute_template "$TEMPLATES_DIR/contributing.md.template" "$DOCS_DIR/src/contributing.md"

echo "✅ Documentation source files generated in $DOCS_DIR"
echo ""
echo "📝 You can now edit the files in $DOCS_DIR/src/ to customize your documentation."
echo "🔧 Run 'just docs-build' to build the HTML documentation from your local files."
echo "📖 Run 'just docs-serve' to start a local development server."
