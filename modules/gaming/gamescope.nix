{
  # gamescope is used as a launch wrapper for games run through Lutris
  # (e.g. Battle.net's `system.prefix_command`). It must be installed
  # declaratively rather than via a throwaway `nix build`: an ad-hoc
  # store path has no GC root, so `nix-collect-garbage` deletes it and
  # the next launch fails with "Check that the file exists" — which is
  # exactly what broke Battle.net once the temporary build was reaped.
  #
  # capSysNice is deliberately OFF. With it on, the gamescope module
  # installs gamescope ONLY as a setcap wrapper under
  # /run/wrappers/bin/gamescope and drops it from systemPackages
  # (see nixpkgs programs/gamescope.nix: `systemPackages = mkIf
  # (!capSysNice) [...]`). That breaks the Lutris launch: Lutris runs
  # games inside a bubblewrap FHS sandbox that sets no_new_privs, so the
  # setcap wrapper can't acquire cap_sys_nice and the spawn fails.
  #
  # With capSysNice off, gamescope lands at the stable
  # /run/current-system/sw/bin/gamescope path — GC-proof, and reachable
  # inside the sandbox because /nix and /run are bind-mounted in. The
  # Battle.net Lutris config's `system.prefix_command` references that
  # absolute path. The lost cap_sys_nice only costs a little scheduling
  # priority; the previous working setup ran without it anyway.
  flake.modules.nixos.gaming = {
    programs.gamescope = {
      enable = true;
      capSysNice = false;
    };
  };
}
