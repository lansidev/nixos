{ pkgs, ... }:
let
  email = "55317770+simlans@users.noreply.github.com";

  # Public ed25519 SSH key used for signing git commits and tags.
  # Public keys are designed to be shared — verifying signatures is the only
  # operation they enable, and GitHub already publishes this key under
  # https://api.github.com/users/simlans/ssh_signing_keys. The matching
  # private key lives only in 1Password and is exposed at runtime via the
  # GUI's ~/.1password/agent.sock (see home/lansing/onepassword.nix).
  signingPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ8KVxjQP4VDhBn3ux8LqstUDjXYHDDVbZgrfVouX4ty";
in
{
  home.packages = [ pkgs.gh ];

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "simlans";
        email = email;
        signingkey = signingPublicKey;
      };

      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";

      gpg.format = "ssh";
      gpg.ssh.allowedSignersFile = "~/.config/git/allowed_signers";

      commit.gpgsign = true;
      tag.gpgsign = true;

      credential.helper = "${pkgs.gh}/bin/gh auth git-credential";
    };
  };

  xdg.configFile."git/allowed_signers".text =
    "${email} ${signingPublicKey}\n";
}
