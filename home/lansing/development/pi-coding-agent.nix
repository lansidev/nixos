{ pkgs, osConfig, ... }:
let
  # simlans/pi-skills is a fork of fgladisch/pi-skills (Felix Gladisch's
  # adapted superpowers + subagent-aware versions). Pi walks
  # ~/.pi/agent/skills/ at startup and on /reload, so any SKILL.md under
  # the pinned tree becomes invokable as `/skill:<name>`. Bump rev + hash
  # to roll forward.
  #
  # Bootstrap: after forking on GitHub, populate `rev` and `hash` via
  #   nix run nixpkgs#nix-prefetch-github -- simlans pi-skills --rev main
  # The placeholder values below intentionally fail the fixed-output
  # derivation so a build error surfaces the missing step.
  piSkills = pkgs.fetchFromGitHub {
    owner = "simlans";
    repo = "pi-skills";
    rev = "575947b6b37a8ac6e635c72d62161ddc52af325b";
    hash = "sha256-ZcVITFhkYN7BflKKWALK+eUa+cUZa7McAuhTGkn+oDw=";
  };

  piProfileName = "pi-dev";

  # Pi extensions, declared **unpinned** on purpose: the `pi-extensions`
  # oneshot service below runs `pi update --extensions` on login, and without
  # a version suffix npm resolves each to its latest release — so every login
  # refreshes to newest (we want current over frozen). This list is the single
  # source of truth. The three unscoped ones are the recommended essentials
  # (nicobailon); the four `@fgladisch/...` are Felix Gladisch's extensions.
  # NB: Felix ships these on **npm**, NOT installable via the old
  # `git:github.com/.../pi-extensions/packages/<name>` syntax — Pi has no
  # git-monorepo subpath support (so the `simlans/pi-extensions` fork is not
  # needed). KEEP IN SYNC with the Mac's ~/.pi/agent/settings.json
  # (docs/pi-coding-agent-macos.md).
  piPackages = [
    "npm:pi-mcp-adapter"
    "npm:pi-subagents"
    "npm:pi-web-access"
    "npm:@fgladisch/pi-bash-approval"
    "npm:@fgladisch/pi-persistent-history"
    "npm:@fgladisch/pi-welcome-message"
    "npm:@fgladisch/pi-user-select"
  ];

  # nono profile for `spi`: Pi run inside a sandbox. Extends nono's built-in
  # `node-dev` base (Node.js runtime + the conservative `default` profile that
  # already denies credentials, keychains, browser data and shell history),
  # then layers on the Pi/Cortecs specifics. Kept in lockstep with the Mac's
  # ~/.config/nono/profiles/pi-dev.json (docs/pi-coding-agent-macos.md): same
  # schema and groups — only the filesystem paths and the linux/macos cache
  # group differ. Verified valid with `nono profile validate` (current nono
  # schema: `groups.include` + `network.allow_domain`, not the older
  # `security.groups` / `proxy_allow`). Re-validate after a rebuild with
  # `nono profile validate pi-dev`.
  #
  # `network_profile = "developer"` is a nono preset covering the toolchain's
  # endpoints (npm, GitHub, the common LLM APIs incl. Anthropic/OpenAI);
  # `allow_domain` adds Cortecs on top.
  piNonoProfile = {
    extends = "node-dev";
    meta.name = piProfileName;
    workdir.access = "readwrite";

    groups.include = [
      "git_config"
      "unlink_protection"
      "user_caches_linux"
    ];

    # No `commands.deny`: nono deprecated it (startup-only, child processes
    # bypass it — not real security) and warns on every run. Docker is gated
    # the real way instead, by denying its socket below.
    filesystem = {
      deny = [ "/var/run/docker.sock" ];
      # `allow` is read+write in the current schema, so no separate `write`.
      allow = [
        "$HOME/.pi"
        "$HOME/.cache"
        "$TMPDIR"
      ];
      read = [
        "$HOME/.agents"
        "$HOME/.config/git"
        "/run/secrets/pi"
        "/run/secrets/git"
        "/nix/store"
      ];
    };

    network = {
      network_profile = "developer";
      allow_domain = [ "api.cortecs.ai" ];
    };
  };
in
{
  # Per-user Pi configuration. The binary itself comes from
  # modules/development/pi-coding-agent.nix on the system side; this file
  # owns the JSON files under ~/.pi/agent/ that we want Nix-managed
  # (settings, models, the pinned skill bundle).
  #
  # Same caveat as ~/.claude/settings.json: once managed, these become
  # read-only symlinks into /nix/store. In-app /settings / /model edits no
  # longer persist — edit this file and `home-manager switch` (or
  # `nixos-rebuild switch`) instead. Everything else under ~/.pi/
  # (sessions, history, packages installed via `pi install`, plugins)
  # stays mutable because home-manager only owns these explicit paths.

  home.packages = [
    # spi: pi inside the nono sandbox profile defined below. Naming
    # follows Jannik's gist (sclaude / spi). The plain `pi` binary stays
    # in PATH for cases where the harness needs full access.
    #
    # `nono` and `pi` are referenced by bare name (not `${pkgs.nono}/bin/...`)
    # because pi-coding-agent and nono live in `nixpkgs-unstable` only —
    # see modules/development/{pi-coding-agent,nono}.nix. They're in
    # /run/current-system/sw/bin via environment.systemPackages, so PATH
    # resolution at exec time picks up whichever version the host has.
    (pkgs.writeShellScriptBin "spi" ''
      # nono refuses to start if ~/.nono/sessions is group/world-accessible,
      # which the default umask 022 produces (755). Force 700 before launch.
      mkdir -p "$HOME/.nono/sessions"
      chmod 700 "$HOME/.nono" "$HOME/.nono/sessions" 2>/dev/null || true
      exec nono run \
        --allow-cwd \
        --profile ${piProfileName} \
        -- pi "$@"
    '')
  ];

  # `packages` is Pi's installed-extension list. On the Mac `pi install`
  # writes it; here settings.json is a read-only Nix symlink, so we declare
  # the list directly and let the `pi-extensions` service fetch the code.
  home.file.".pi/agent/settings.json".text = builtins.toJSON {
    transport = "auto";
    enableInstallTelemetry = false;
    packages = piPackages;
  };

  # Cortecs custom provider (OpenAI-compatible). `apiKey: "!…"` is Pi's
  # shell-command syntax — resolved per-request from the sops-decrypted
  # file, no env-var leak. The cortecs base URL is documented at
  # https://docs.cortecs.ai/.
  #
  # Cortecs only serves EU-hosted, GDPR-compliant ("sovereign") models, so
  # this `models` array is effectively the allow-list — only what's listed
  # shows up under `/model`. Keep it to the European models we want. List the
  # live catalog with `curl -s https://api.cortecs.ai/v1/models -H "Authorization:
  # Bearer $(cat <key>)" | jq '.data[].id'`, then edit this file and
  # `home-manager switch`. Each entry only requires `id`; the rest are
  # optional overrides. KEEP IN SYNC with the Mac's ~/.pi/agent/models.json
  # (docs/pi-coding-agent-macos.md) — same model IDs on every machine.
  home.file.".pi/agent/models.json".text = builtins.toJSON {
    providers.cortecs = {
      baseUrl = "https://api.cortecs.ai/v1";
      api = "openai-completions";
      apiKey = "!cat ${osConfig.sops.secrets."pi/cortecs_api_key".path}";
      authHeader = true;
      models = [
        {
          id = "devstral-2512";
          name = "Devstral 2 2512 (Cortecs)";
          contextWindow = 262000;
        }
      ];
    };
  };

  # Skill bundle: symlink the repo's skills/ subdir into pi's discovery
  # path. Each subdirectory inside becomes a skill (SKILL.md +
  # supporting files).
  home.file.".pi/agent/skills/pi-skills".source = "${piSkills}/skills";

  # Nono profile JSON. Lives at ~/.config/nono/profiles/pi-dev.json so
  # `nono run --profile pi-dev` (i.e. the spi wrapper) picks it up.
  xdg.configFile."nono/profiles/${piProfileName}.json".text =
    builtins.toJSON piNonoProfile;

  # Fetch the declared extensions automatically. `pi install` can't be used
  # on NixOS (it writes settings.json, a read-only symlink here), so the list
  # lives in settings.json above and this oneshot runs `pi update
  # --extensions` to pull the missing code into the writable ~/.pi/agent/npm.
  # `--extensions` never touches the read-only pi binary; the run is
  # idempotent (a no-op once everything is present). `/login` still has to be
  # done once per host by hand — it's an interactive OAuth flow.
  systemd.user.services.pi-extensions = {
    Unit = {
      Description = "Sync declared Pi coding-agent extensions";
      # Advisory: user units can't strictly order against the system
      # network-online.target, but this nudges it later in the sequence.
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      # pi comes from the system module (nixpkgs-unstable) in
      # /run/current-system/sw/bin; user units have a minimal PATH, so call it
      # by absolute path.
      ExecStart = "/run/current-system/sw/bin/pi update --extensions";
      # Tie the unit to the package list so `home-manager switch` restarts
      # (and re-syncs) whenever the list changes.
      Environment =
        "PI_PACKAGES_HASH=${builtins.hashString "sha256" (builtins.concatStringsSep "," piPackages)}";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
