{...}: {
  home.shellAliases = {
    # Overrides
    ll = "eza -l --icons=always --group-directories-first --git --color=always";
    la = "eza -la --icons=always --group-directories-first --git --color=always";
    ls = "eza --icons=always --group-directories-first --color=always";
    lt = "eza --tree --icons=always --group-directories-first --color=always";
    tree = "eza --tree --icons";
    cat = "bat --paging=always --color=always";
    grep = "rg";
    find = "fd";

    # Overrides: Utilities
    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";
    mkdir = "mkdir -p";
    df = "df -h";
    du = "du -h";
    free = "free -h";

    # Git shortcuts
    # g function is defined in zsh.nix for profile support
    gs = "git status";
    ga = "git add";
    gc = "git commit";
    gp = "git push";
    gl = "git pull";
    gd = "git diff";
    gco = "git checkout";
    gbr = "git branch";
    glog = "git log --oneline --graph --decorate";

    # System management
    rebuild = "sudo nixos-rebuild switch --flake .#nixos-wsl";
    update-system = "nix flake update && rebuild";
    cleanup = "sudo nix-collect-garbage -d && nix-collect-garbage -d";

    # Development
    fmt = "nix fmt";
    check = "nix flake check";
    dev = "nix develop";

    # Docker shortcuts
    d = "docker";
    dc = "docker-compose";
    dps = "docker ps";
    di = "docker images";
    dn = "docker network ls";

    # Network
    myip = "curl -s https://httpbin.org/ip | jq -r .origin";
    ports = "netstat -tuln";

    # Quick edits
    zshrc = "$EDITOR ~/.zshrc";
    vimrc = "$EDITOR ~/.vimrc";
    bashrc = "$EDITOR ~/.bashrc";
    tmuxconf = "$EDITOR ~/.tmux.conf";
    gitconfig = "$EDITOR ~/.gitconfig";

    # System info
    sysinfo = "fastfetch";
    z = "zoxide";

    # Miscellaneous
    v = "nvim";
  };
}
