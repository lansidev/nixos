# TODO

## NixOS 26.05 upgrade

`flake.nix` points at `nixos-26.05` / `home-manager release-26.05`. battlestation is switched and live as of 2026-06-11 (generation `26.05.20260608.bd0ff2d (Yarara)`). workstation has not been switched yet. `system.stateVersion` and `home.stateVersion` deliberately stay on `"25.11"` (they pin install-time defaults, not the channel).

- [ ] Switch the workstation laptop to 26.05 (`sudo nixos-rebuild switch --flake .#workstation`); it shares the same flake so the same blockers / cleanups apply.
- [x] **Noctalia v4 → v5 migration** done. `flake.nix` now pins an explicit v5 (main) commit; `modules/desktop/noctalia.nix` ported to the v5 schema (`programs.noctalia`, `theme`/`location`/`hooks.started`, `bar.main.{start,center,end}`, per-widget `[widget.<id>]` tables — note the IDs are `sysmon` and `active_window`, not the dashed forms first guessed). `modules/desktop/niri.kdl` was migrated alongside it: the startup spawn and the launcher/lock/session-menu binds moved from the old `noctalia-shell ipc call …` syntax to the `noctalia msg …` syntax. Clock weekday/month names render in English (kept the `en_US.UTF-8` default locale). Layer-shell namespaces verified against the v5 source (`7421f80`): v5 dropped per-instance suffixes and uses flat names, so the old `^noctalia-(background|launcher-overlay|dock)-.*$` rule matched nothing — updated to `^noctalia-(backdrop|panel|attached-panel|dock|overview-launcher)$` (`background`→`backdrop`, `launcher-overlay`→`panel`/`overview-launcher`). The wallpaper rule still matches (`noctalia-wallpaper`, confirmed live via `niri msg layers`).
- [ ] **Re-evaluate the "unstable because stable lags" workarounds** once the build is green on 26.05 — several were justified against 25.11 specifically:
  - `modules/development/claude-code.nix` — comment said 25.11 lagged ~30 patches.
  - `modules/desktop/niri.nix` — comment said 25.11 ships 25.11, unstable ships 26.04; 26.05 may now ship a recent-enough niri.
  - `modules/development/vscodium.nix` — manifest lag concern.
  - `modules/gaming/lutris.nix` — 25.11 shipped 0.5.19.
  - `modules/development/pi-coding-agent.nix` — was not packaged in 25.11 at all; check 26.05.
- [x] **Home-manager neovim defaults flipped in 26.05.** Adopted the new `false` defaults explicitly: `programs.neovim.withRuby = false; withPython3 = false;` in `modules/development/neovim.nix` (LazyVim is lua-only).
- [x] **Home-manager option renames surfaced on the 26.05 switch.** All migrated and verified with a clean `nixos-rebuild build` (no eval warnings):
  - `programs.neovim.extraLuaConfig` → `programs.neovim.initLua` in `modules/development/neovim.nix`.
  - `programs.vscode` → `programs.vscodium` (its own module) in `modules/development/vscodium.nix`; the manual `.vscode-oss/argv.json` `home.file` was replaced by the module's `argvSettings` (it writes to `.vscode-oss/` natively).
  - `programs.ssh.matchBlocks."*"` → `programs.ssh.settings."*"` in `modules/apps/onepassword.nix`, rewritten with upstream OpenSSH directive names (`IdentityAgent`, `ForwardAgent`, …) instead of the camelCase aliases.

- [x] Replace Discord with Vesktop (open-source client) — screen sharing doesn't work in Discord
- [x] Switch font away from the current one to something with a finer style
- [x] Adjust tmux colors to match Catppuccin — remapped the 17 `tmux_conf_theme_colour_*` variables in `modules/shell/tmux/tmux.conf.local` (oh-my-tmux default theme) to Catppuccin Mocha pastels, keeping the existing layout (yellow session / pink arrow / blue window / red user / grey host). Dark Crust text on the lighter pastel accents for legibility; hostname moved from white to a Surface2 grey with Text-coloured foreground.
- [ ] Rename Tailscale host — "battlestation" is already taken by the Windows machine
- [x] Install OpenCloud
- [x] Install a suitable file manager (yazi)
- [x] Readd Mod+D besides Mod+Space to open app launcher
- [x] Use Noctalia Login screen alternative
- [x] Add own workspace "gaming" for Steam
- [x] VSCode Terminal shows square icon instead of a NixOS Flake symbol
- [x] Wire up the Elgato Cam Link 4K (USB HDMI capture) so it shows up as a v4l2 source for video calls / OBS
- [x] Fixed `applyLocalFullName` activation script in `modules/system/users.nix`: it called `${pkgs.coreutils}/bin/getent`, but `getent` is not in coreutils (it's glibc). Replaced with `${pkgs.getent}/bin/getent` (the dedicated glibc-getent package — cleaner than `${pkgs.glibc.bin}/bin/getent`). Verified the built activate script now references `getent-glibc`. Done in `d1a4d3d`.

## Battle.net + WoW on niri — solved without gamescope

**Problem:** Battle.net (Lutris → GE-Proton via `umu-run`) was unusable on niri — after login the CEF main window never surfaced (Battle.net minimizes to a tray, but niri has no XEmbed tray host, so only a tiny white tray stub appears mid-screen). The login screen also rendered white/broken.

**Real root cause:** Battle.net's **browser hardware acceleration** under Wayland — the classic CEF white/invisible-window bug (`GloriousEggroll/proton-ge-custom#427`). gamescope had been used as a workaround (its own nested X server + clean GPU context made the window appear with HW-accel on), but it was the wrong tool: gamescope's direct-scan-out path corrupts D3D12 output on AMD (`ValveSoftware/gamescope#1293`, kernel >= 6.8) — that was the source of the turquoise/magenta smearing in WoW when turning the camera.

**Fix — gamescope removed entirely:**

- [x] **Disable Battle.net browser HW acceleration.** Battle.net → Settings → App → uncheck "Use browser hardware acceleration" => `Battle.net.config` `HardwareAcceleration: "false"`. The launcher now renders and surfaces natively on niri. (Only affects the launcher UI — never WoW's own renderer.)
- [x] **Drop the gamescope launch prefix.** Lutris → System options → cleared the "Command prefix" (was `/run/current-system/sw/bin/gamescope -W 3440 -H 1440 -r 100 -f --force-grab-cursor --`). Battle.net and WoW now run native under niri / xwayland-satellite.
- [x] **Delete `modules/gaming/gamescope.nix`** (`programs.gamescope`). Nothing else referenced it; import-tree drops it from the config automatically.

**Known remaining issues (upstream / user-state, NOT this repo):**

- **WoW ray tracing crashes the GPU.** Enabling RT faults the card: `amdgpu ... Process WoW.exe thread vkd3d_queue ... page fault ... GCVM_L2_PROTECTION_FAULT ... ring gfx_0.0.0 timeout ... device wedged, but recovered through reset` — hence the black-screen / window-thrash loop. Known RDNA4/RADV/VKD3D driver bug on GFX1201 + Mesa 26.1.x (publicly reported), not config-fixable. RT left **off** pending an upstream Mesa fix — revisit by pulling a newer mesa from `nixpkgs-unstable` (`hardware.graphics.package` / `package32`) once the RDNA4 RT fix lands. Note: RADV env-var workarounds are long shots AND **Lutris/Battle.net env vars don't reach the game** — umu's pressure-vessel container filters them (verified: `RADV_DEBUG`/`DXVK_HUD` absent from `WoW.exe` `/proc/<pid>/environ`); to test, launch via `env RADV_PERFTEST=... lutris` instead.
- **niri tray stub.** niri has no XEmbed tray host, so a small white Battle.net tray stub sits mid-screen until WoW launches. Cosmetic; could be hidden with a niri window rule (mirror the Steam rules in `modules/gaming/steam.nix`).
- **User-state in `~`:** the Lutris game yml `~/.local/share/lutris/games/battlenet-1781209761.yml` and the Wine prefix `/home/lansing/Games/battlenet` incl. `Battle.net.config`. Battle.net can't paste from the niri clipboard — type the password once; AutoLogin remembers it.

## Errors to investigate

- [ ] **OpenCloud GUI: QtQuick.Controls plugin not found.**
  ```
  QList(qrc:/qt/qml/eu/OpenCloud/gui/qml/AccountBar.qml:16:1: module "QtQuick.Controls" plugin "qtquickcontrols2plugin" not found
      import QtQuick.Controls
      ^)
  ```
- [ ] **Yazi eval warning: `programs.yazi.shellWrapperName` default changed.** The default changed from `"yy"` to `"y"`. Currently using the legacy default (`"yy"`) because `home.stateVersion` is less than `"26.05"`. To silence the warning and keep legacy behavior, set `programs.yazi.shellWrapperName = "yy";`. To adopt the new default, set `programs.yazi.shellWrapperName = "y";`.
- [ ] **VSCodium: configure git `user.name` and `user.email`.** VSCodium warns: "Make sure you configure your `user.name` and `user.email` in git."
