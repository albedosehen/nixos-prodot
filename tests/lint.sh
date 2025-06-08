#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix alejandra deadnix statix
# shellcheck shell=bash

set -euo pipefail

echo "🔧 Running validation and linting..."

echo "(alejandra): format check..."
if alejandra --check .; then
  echo "✅ Alejandra formatting check passed"
else
  echo "❌ Alejandra formatting issues found"
  echo "Run 'alejandra .' to fix formatting"
  exit 1
fi

echo "(deadnix): Deadcode check..."
if deadnix --fail .; then
  echo "✅ No dead code found"
else
  echo "❌ Dead code detected"
  echo "Run 'deadnix --edit .' to remove dead code"
  exit 1
fi

echo "(statix): Static analysis ..."
if statix check .; then
  echo "✅ Static analysis passed"
else
  echo "❌ Static analysis issues found"
  echo "Run 'statix fix .' to fix issues"
  exit 1
fi

echo "(nix): Configuration structure check..."
if nix eval --json .#nixosConfigurations.nixos-wsl.config.system.build.toplevel.drvPath >/dev/null; then
  echo "✅ Configuration structure valid"
else
  echo "❌ Configuration structure invalid"
  exit 1
fi

echo "(nix): Flake structure check..."
if nix flake show >/dev/null 2>&1; then
  echo "✅ Flake structure valid"
else
  echo "❌ Flake structure invalid"
  exit 1
fi

echo "🎉 All linting checks passed!"
