# Pre-commit hooks (gitleaks). `nix flake check` runs the suite; the
# devShell's shellHook installs `.git/hooks/pre-commit` so direnv users
# get the guard automatically on first entry into the repo.
{ inputs, ... }:
{
  perSystem = { pkgs, system, ... }:
    let
      pre-commit-check = inputs.git-hooks.lib.${system}.run {
        src = inputs.self;
        hooks.gitleaks = {
          enable = true;
          name = "gitleaks";
          description = "Scan staged content for secrets";
          entry = "${pkgs.gitleaks}/bin/gitleaks protect --staged --redact --verbose";
          pass_filenames = false;
        };
      };
    in
    {
      checks.pre-commit = pre-commit-check;

      devShells.default = pkgs.mkShell {
        inherit (pre-commit-check) shellHook;
        buildInputs = pre-commit-check.enabledPackages;
      };
    };
}
