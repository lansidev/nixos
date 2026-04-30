{ ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 100000;
      save = 100000;
      extended = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      saveNoDups = true;
      share = true;
    };

    shellAliases = {
      k = "kubectl";
      kgp = "kubectl get pods";
      kgs = "kubectl get svc";
      kga = "kubectl get all";
      kaf = "kubectl apply -f";
      ll = "ls -la";
      ".." = "cd ..";
      "..." = "cd ../..";
    };

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "kubectl"
        "z"
        "sudo"
        "colored-man-pages"
      ];
    };

    # Mirrors the dev-remote .zshrc tail. Skipped on the workstation:
    # the SSH-agent bootstrap (handled by the 1Password GUI agent now) and
    # the runtime `git config --global` mutations (declared in git.nix).
    initContent = ''
      # Fall back to xterm-256color for unknown terminfo entries (e.g. xterm-ghostty)
      if ! infocmp "$TERM" &>/dev/null 2>&1; then
        export TERM=xterm-256color
      fi

      # Minimal prompt — same as on the dev-remote VM
      ZSH_THEME=""
      PROMPT='%F{blue}%1~%f %# '

      # PATH for user-installed tooling that lives outside the Nix store
      export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"
      export COLORTERM=truecolor

      # 1Password CLI signin (idempotent; only if not already signed in)
      if command -v op >/dev/null && ! op whoami --account my.1password.eu &>/dev/null; then
        eval "$(op signin --account my.1password.eu)"
        if [ -n "$TMUX" ]; then
          for var in $(env | grep '^OP_SESSION_'); do
            tmux setenv "''${var%%=*}" "''${var#*=}"
          done
        fi
      fi
    '';
  };
}
