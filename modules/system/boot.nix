{ pkgs, ... }:
{
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
    autoGenerateKeys.enable = true;
    autoEnrollKeys.enable = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [ "amd_pstate=active" ];

  environment.systemPackages = [ pkgs.sbctl ];

  # Lanzaboote signs the UKI at /boot/EFI/Linux/ (the actual Secure Boot
  # entry point), but NixOS' bootspec layer also drops a bare kernel at
  # /boot/EFI/nixos/kernel-*.efi that lanzaboote does not sign. It is not
  # on the boot path — the UKI is self-contained — but `sbctl verify` flags
  # it as unsigned, and a future fallback boot path could try to chainload
  # it. Sign whatever exists there once the lanzaboote keys are in place.
  systemd.services.sign-bare-kernel = {
    description = "Sign bare kernel files left at /boot/EFI/nixos/";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      if [ -d /etc/secureboot/keys ]; then
        for f in /boot/EFI/nixos/kernel-*.efi; do
          [ -e "$f" ] || continue
          ${pkgs.sbctl}/bin/sbctl sign "$f"
        done
      fi
    '';
  };
}
