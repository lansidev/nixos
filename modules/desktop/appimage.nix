# AppImage support — register a binfmt_misc handler so AppImages run
# directly (`./Foo.AppImage`) instead of failing with "Could not start
# dynamically linked executable". NixOS ships no generic /lib64 dynamic
# linker, so AppImages built for ordinary distros can't exec out of the
# box; appimage-run provides the FHS runtime, and `binfmt = true` makes
# the kernel route every `.AppImage` exec through it transparently.
# Needed for apps distributed only as an AppImage with no nixpkgs
# package — e.g. the CurseForge Minecraft launcher.
{
  flake.modules.nixos.desktop = {
    programs.appimage = {
      enable = true;
      binfmt = true;
    };
  };
}
