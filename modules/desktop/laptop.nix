# Generic laptop behaviour, pulled in only by laptop hosts. Deliberately
# hardware-agnostic: device-specific bits (nixos-hardware profile,
# fingerprint reader, vendor thermal daemons) live in the host module
# (e.g. modules/hosts/workstation.nix), so a future laptop with different
# silicon can reuse this bucket as-is.
{
  flake.modules.nixos.laptop = { lib, ... }: {
    # Power-manager policy: hardware profiles such as nixos-hardware's
    # common-pc-laptop like to flip services.tlp.enable on. We run
    # power-profiles-daemon (modules/desktop/power.nix), which TLP
    # refuses to coexist with — force TLP off so ppd stays the single
    # power manager on every laptop host.
    services.tlp.enable = lib.mkForce false;

    # Laptop vendors (Framework, Lenovo, …) distribute BIOS + EC
    # firmware via LVFS.
    services.fwupd.enable = true;

    # Don't suspend when the lid closes while plugged in — sensible for
    # docked-laptop usage. NixOS 25.11 migrated logind options to the
    # `settings` map (mirroring the upstream `[Login]` ini section).
    services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";
  };
}
