{ ... }:
{
  # Ships `fzf` and the standard zsh keybindings: Ctrl+R fuzzy history,
  # Ctrl+T file picker, Alt+C cd-to-directory, plus `**<TAB>` completion.
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
}
