{pkgs, ...}: {
  imports = [
    ./aliases.nix
    ./bat.nix
    ./eza.nix
    ./fastfetch.nix
    ./starship.nix
    ./zsh.nix
    ./btop.nix
    ./fzf.nix
    ./direnv.nix
    ./tmux.nix
  ];

  home.packages = with pkgs; [
    ### Core
    tree
    unzip
    zoxide
    ripgrep
    fd
    ### Development tools
    just
    alejandra
    nil
    nixpkgs-fmt
    deadnix
    statix
    gh
    ### Text processing
    jq
    yq
    xmlstarlet
    difftastic
    delta
    ### Scripting
    shellcheck
    shfmt
    pre-commit
    docker-compose
    ### System monitoring
    htop
    iotop
    bandwhich
    ### Performance measurement
    hyperfine
    wrk
    ### Security
    age
    sops
  ];
}
