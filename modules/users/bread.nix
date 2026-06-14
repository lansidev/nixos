# Example second user, structurally identical to lansing via the shared builder
# (lib/mk-user.nix) — proof that the host modules are decoupled from any
# specific username. A host gets bread by importing nixos.user-bread.
import ../../lib/mk-user.nix {
  username = "bread";
  sshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFSIDoZWfx6cHP0Tp1xwi6cBnYopSd2YHbFugA7t32KN"
  ];
}
