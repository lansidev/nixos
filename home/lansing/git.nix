{ pkgs, ... }:
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
        email = "55317770+simlans@users.noreply.github.com";
      };

      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
      credential.helper = "${pkgs.gh}/bin/gh auth git-credential";

      # SSH-based commit signing via the 1Password GUI agent
      # (~/.1password/agent.sock, wired in onepassword.nix).
      #
      # To enable signing on this host:
      #   1. In the 1Password GUI: Settings → Developer → enable
      #      "Use the SSH agent" (the agent socket appears once the
      #      GUI has been launched and signed in).
      #   2. Replace the placeholder below with the matching public key:
      #        op read 'op://Private/GitHub Signing Key/public key'
      #   3. Flip `signByDefault = true;` and remove this note.
      #
      # gpg.format = "ssh";
      # gpg.ssh.allowedSignersFile = "~/.config/git/allowed_signers";
      # commit.gpgsign = true;
      # tag.gpgsign = true;
      # user.signingkey = "ssh-ed25519 REPLACE_ME";
    };
  };

  # Allowed signers file is set up alongside the key — keep this commented
  # out until the key value is filled in above.
  #
  # xdg.configFile."git/allowed_signers".text =
  #   "55317770+simlans@users.noreply.github.com ssh-ed25519 REPLACE_ME\n";
}
