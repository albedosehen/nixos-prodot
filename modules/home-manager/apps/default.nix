{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./git.nix
  ];

  home.packages = with pkgs; [
    ### Core utilities
    neofetch
    ### Archive tools
    p7zip
    zip
    ### Network debugging
    nmap
    tcpdump
    httpie
    curl
    wget
    curlie
    ### Debugging
    strace
    ltrace
    gdb
    ### Build tools
    gnumake
    cmake
    ### Git tools
    lazygit
    gitui
    ### Documentation
    mdbook
    pandoc
    ### Neovim
    inputs.nixvim.packages.${pkgs.system}.default
  ];
}
