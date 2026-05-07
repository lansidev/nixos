{ ... }:
{
  imports = [
    ./claude-code.nix
    ./git.nix
    ./golang.nix
    ./kubernetes
    ./neovim
    ./vscode.nix
  ];
}
