{ ... }:
let
  # Color the tmux window of the current Claude session based on state, so
  # multiple parallel sessions are visually distinguishable in the status
  # bar. No-op when $TMUX is unset (Claude launched outside tmux). Always
  # exits 0 so the harness never sees a hook failure.
  tmuxColor = style:
    ''[ -n "$TMUX" ] && tmux set-window-option -t "$TMUX_PANE" window-status-style '${style}' >/dev/null 2>&1; exit 0'';
  tmuxReset =
    ''[ -n "$TMUX" ] && tmux set-window-option -u -t "$TMUX_PANE" window-status-style >/dev/null 2>&1; exit 0'';
  cmdHook = command: [ { hooks = [ { type = "command"; inherit command; } ]; } ];
in
{
  # Per-user Claude Code config. The package itself comes from
  # modules/development/claude-code.nix on the system side; this file owns
  # ~/.claude/settings.json, the only piece that is meaningfully
  # user-scoped (preferences, attribution, default permission mode).
  #
  # Once managed, ~/.claude/settings.json becomes a read-only symlink into
  # /nix/store. Tweaking via the in-app `/config` or `/model` slash
  # commands no longer works — edit this file and run `home-manager
  # switch` (or `nixos-rebuild switch`) instead. All other state under
  # ~/.claude/ (sessions, history, projects, plugins) stays mutable
  # because home-manager only owns this one path.
  home.file.".claude/settings.json".text = builtins.toJSON {
    model = "opus[1m]";
    skipAutoPermissionPrompt = true;
    permissions = {
      defaultMode = "auto";
    };
    # Empty strings disable Claude Code's default commit/PR attribution
    # (the "Co-Authored-By: Claude …" trailer and the "🤖 Generated
    # with Claude Code" line). Repo-level enforcement also lives in
    # AGENTS.md, but the harness setting is what actually stops the
    # trailer from being appended at commit time.
    attribution = {
      commit = "";
      pr = "";
    };
    # tmux window coloring per session state:
    #   Stop             — Claude finished, awaiting input → yellow
    #   Notification     — blocked on permission / idle    → red
    #   UserPromptSubmit — work resumed                    → reset
    hooks = {
      Stop = cmdHook (tmuxColor "fg=black,bg=yellow,bold");
      Notification = cmdHook (tmuxColor "fg=white,bg=red,bold");
      UserPromptSubmit = cmdHook tmuxReset;
    };
  };
}
