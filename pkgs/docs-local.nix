{
  lib,
  pkgs,
  ...
}: let
  docsPath = ../docs;
in
  pkgs.stdenv.mkDerivation {
    pname = "nixos-prodot-files-local";
    version = "1.0.0";

    src = docsPath;

    buildInputs = with pkgs; [
      mdbook
    ];

    buildPhase = ''
      if [ ! -f "book.toml" ]; then
        echo "Error: book.toml not found in docs directory"
        echo "Please run 'just docs-generate' first to create the source files"
        exit 1
      fi

      if [ ! -d "src" ]; then
        echo "Error: src directory not found in docs directory"
        echo "Please run 'just docs-generate' first to create the source files"
        exit 1
      fi

      # Build the documentation with mdbook
      mdbook build
    '';

    installPhase = ''
      mkdir -p $out
      if [ -d "book" ] && [ "$(ls -A book 2>/dev/null)" ]; then
        echo "Found book directory, copying contents..."
        cp -r book/* $out/
      else
        echo "Error: book directory is empty or doesn't exist"
        echo "Current working directory: $(pwd)"
        echo "Contents of current directory:"
        ls -la
        exit 1
      fi
    '';

    meta = with lib; {
      description = "Documentation for NixOS Profile-Based Dotfile configuration (built from local files)";
      license = licenses.mit;
      platforms = platforms.all;
    };
  }
