# Bootstrap helpers exposed as `nix run .#<name>` apps. They support the
# install/onboarding flow documented in README.md and are independent of
# any particular host configuration.
{
  perSystem = { pkgs, ... }: {
    apps = {
      # `nix run .#sops-onboard-host -- <ssh-target> <name>` — bootstrap
      # a new machine into sops in one shot. SSHs to <ssh-target>, reads
      # its ed25519 SSH host pubkey, converts it to an age recipient,
      # inserts it into `.sops.yaml` (right before the existing
      # `&user_*` anchor + `*user_*` reference), and runs
      # `sops updatekeys` so `secrets/personal.yaml` is re-encrypted
      # for the new host. Idempotent: re-running with an already-
      # onboarded `<name>` is a no-op. The local user needs:
      #   - SSH access to the target (the 1P SSH agent serves the
      #     authorized key declared in the openssh module),
      #   - `SOPS_AGE_KEY` in the environment so this script's
      #     `sops updatekeys` call can decrypt before re-encrypting.
      #     The repo's `.envrc` exports it from 1Password
      #     (`op://Private/nixos-sops-keyfile`), so running `nix run`
      #     from inside the direnv'd repo shell is sufficient —
      #     no on-disk `~/.config/sops/age/keys.txt` required.
      # Run from inside the repo so direnv has loaded the env.
      # Prints the remaining git/rebuild commands to stdout when done.
      sops-onboard-host = {
        type = "app";
        program = "${pkgs.writeShellApplication {
          name = "sops-onboard-host";
          runtimeInputs = with pkgs; [
            openssh
            ssh-to-age
            sops
            gawk
            gnugrep
            coreutils
            git
          ];
          text = ''
            if [ $# -lt 2 ]; then
              cat >&2 <<'USAGE'
            usage: nix run .#sops-onboard-host -- <ssh-target> <flake-host>

              <ssh-target>  network address for the pubkey fetch. Anything
                            `ssh` accepts — IP, hostname, Tailscale MagicDNS,
                            ~/.ssh/config alias. e.g. lansing@192.168.1.42,
                            lansing@workstation.local, lansing@workstation.
              <flake-host>  logical name. Becomes `&host_<flake-host>` in
                            .sops.yaml and the `#<flake-host>` target of
                            `nixos-rebuild --flake .#<flake-host>`. Must
                            match a `nixosConfigurations.<name>` entry —
                            currently `battlestation` or `workstation`.

            Most-common case (DNS resolves the name): both args identical, e.g.
              nix run .#sops-onboard-host -- lansing@workstation workstation
            USAGE
              exit 1
            fi
            target="$1"
            name="$2"

            repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
              echo "ERROR: not in a git repo (run from inside nixos/)" >&2
              exit 1
            }
            cd "$repo_root"

            [ -f .sops.yaml ] || { echo "ERROR: $repo_root/.sops.yaml not found" >&2; exit 1; }
            [ -f secrets/personal.yaml ] || { echo "ERROR: $repo_root/secrets/personal.yaml not found" >&2; exit 1; }

            if grep -q "&host_$name " .sops.yaml; then
              echo "host_$name already present in .sops.yaml; nothing to do" >&2
              exit 0
            fi

            # The awk insertion uses the user_* anchor/reference as the
            # "before this line" marker — fail loudly if the convention
            # has drifted, instead of silently producing a malformed file.
            grep -q "^  - &user_" .sops.yaml \
              || { echo "ERROR: .sops.yaml has no '&user_*' anchor to insert before" >&2; exit 1; }
            grep -q "^          - \*user_" .sops.yaml \
              || { echo "ERROR: .sops.yaml has no '*user_*' reference to insert before" >&2; exit 1; }

            echo "==> fetching SSH host pubkey from $target" >&2
            pubkey=$(ssh "$target" 'cat /etc/ssh/ssh_host_ed25519_key.pub' | ssh-to-age)
            [ -n "$pubkey" ] || { echo "ERROR: empty age pubkey from $target" >&2; exit 1; }
            echo "    $pubkey" >&2

            echo "==> inserting host_$name into .sops.yaml" >&2
            tmp=$(mktemp)
            awk -v name="$name" -v pubkey="$pubkey" '
              /^  - &user_/ && !did_key { print "  - &host_" name " " pubkey; did_key = 1 }
              /^          - \*user_/ && !did_ref { print "          - *host_" name; did_ref = 1 }
              { print }
            ' .sops.yaml > "$tmp"
            mv "$tmp" .sops.yaml

            echo "==> re-encrypting secrets/personal.yaml" >&2
            sops updatekeys --yes secrets/personal.yaml

            cat <<EOF

            Done. Now (locally):
              git -C $repo_root commit -am "sops: onboard $name"
              git -C $repo_root push

            Then on $name:
              git pull
              sudo nixos-rebuild switch --flake ~/Projects/nixos#$name
            EOF
          '';
        }}/bin/sops-onboard-host";
      };

      # `nix run .#tailscale-up` — bootstrap this node into the tailnet.
      # Default is browser-based auth: `tailscale up` prints a one-time
      # login URL on first run. Optional: pipe an auth key on stdin
      # (`echo "$key" | nix run .#tailscale-up`) to skip the browser.
      # Calls `sudo tailscale up` with the standard --accept-dns
      # --accept-routes flags. Single-shot: tailscale persists the node
      # identity under /var/lib/tailscale.
      tailscale-up = {
        type = "app";
        program = "${pkgs.writeShellApplication {
          name = "tailscale-up";
          runtimeInputs = [ pkgs.tailscale ];
          text = ''
            if [ ! -t 0 ]; then
              key="$(cat)"
              exec sudo tailscale up \
                --auth-key="$key" \
                --accept-dns \
                --accept-routes
            fi
            exec sudo tailscale up \
              --accept-dns \
              --accept-routes
          '';
        }}/bin/tailscale-up";
      };

      # `nix run .#init-account` — install-time bootstrap for the
      # `lansing` account: sets the login password via
      # `nixos-enter -c 'passwd lansing'` and seeds the GECOS source
      # file at `<root>/etc/nixos/local/full-name`. Optional positional
      # argument is the mount point of the freshly-installed system
      # (default `/mnt`, i.e. wherever disko-install left the new
      # rootfs). Combines what the README used to spell out as two
      # commands so the whole post-disko-install bootstrap fits in a
      # single `nix run` invocation. To change the realname later on a
      # running system, just edit `/etc/nixos/local/full-name` directly
      # and run `nixos-rebuild switch` — the activation script in
      # the users module re-applies it via usermod.
      init-account = {
        type = "app";
        program = "${pkgs.writeShellApplication {
          name = "init-account";
          runtimeInputs = [ pkgs.coreutils ];
          text = ''
            root="''${1:-/mnt}"

            if [ ! -d "$root/etc" ]; then
              echo "no NixOS root found at $root (expected $root/etc)" >&2
              echo "pass the mount point as the first argument if it is not /mnt" >&2
              exit 1
            fi

            echo "==> Setting login password for user lansing (in $root)" >&2
            sudo nixos-enter --root "$root" -c 'passwd lansing'

            echo "" >&2
            echo "==> Setting GECOS / lock-screen real name" >&2
            IFS= read -rp 'Full name (e.g. "Lansing Surname"): ' name
            if [ -z "$name" ]; then
              echo 'no name given; password is set, but GECOS file was NOT created.' >&2
              echo "Write '$root/etc/nixos/local/full-name' yourself before reboot," >&2
              echo "or edit '/etc/nixos/local/full-name' on the running system later." >&2
              exit 0
            fi
            case "$name" in
              *:*)
                echo 'name must not contain ":" (would corrupt /etc/passwd)' >&2
                exit 1
                ;;
            esac
            target="$root/etc/nixos/local/full-name"
            printf '%s\n' "$name" | sudo install -Dm644 /dev/stdin "$target"
            echo "wrote: $target" >&2
          '';
        }}/bin/init-account";
      };
    };
  };
}
