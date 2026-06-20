# Agent environment

This repository's development environment is provided by the Nix flake. In
FaradAI, `/nix/store` is intentionally read-only: agents may use shell inputs
that were built on the host, but may not add packages or build new store paths.

## Enter the dev shell

Do **not** run `nix develop .` from a dirty checkout. Nix snapshots the local
worktree into a new store path, which needs a store write and fails in FaradAI.

Instead, enter the shell through the current committed revision:

```bash
nix develop 'git+file:///home/josiah/Development/personal/education/self/polyparadigm-project/cinnabar?rev=1a90a5e62aca85dfcb7af05c26ec45466031a73f'
```

For a non-interactive command, append `--command`:

```bash
nix develop 'git+file:///home/josiah/Development/personal/education/self/polyparadigm-project/cinnabar?rev=1a90a5e62aca85dfcb7af05c26ec45466031a73f' --command mmc --version
```

The commit-pinned Git URL ignores uncommitted changes and resolves to the
source and dev-shell closure prepared by the host. The shell includes Mercury
22.01.8 (`mmc`).

## When the checked-out commit changes

Replace `rev=` with the output of `git rev-parse HEAD`. This will work only if
FaradAI has prebuilt that revision's flake closure. If it has not, do not try to
make `/nix/store` writable; ask for that revision's dev shell to be prebuilt on
the host.

An ignored message about creating `/nix/store/tmp-*` may appear during shell
startup. It is harmless when `nix develop` exits successfully.
