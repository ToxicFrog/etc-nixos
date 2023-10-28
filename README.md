These are the NixOS configuration files for ancilla and other systems that I administer.

## Caveat Lector

This repo will not work out of the box; in particular:

- The flake (and some packages) depend on local source code that exists only on my dev machines.
- The `secrets/` directory is encrypted with `git-crypt` and the files will show up as binary garbage. This is intentional.
- History has been rewritten to remove stray PII and other secrets. Historical commits may not compile even with the appropriate version of nixpkgs.

## Navigation

This is a flake-based repo, containing configuration for multiple systems. In addition to the top-level flake files, the `push` script is a simple wrapper around `nixos-rebuild` that builds a given system locally and pushes it over ssh.

### secrets/

This encrypted directory contains password hashes, API keys, and similar. It is decrypted using `git-crypt` on deployment.

### shared/

This contains shared configuration, some shared between all systems like `common.nix` and some used only for a subset of them. Which modules are used on which systems is specified in `flake.nix`.

#### shared/modules/

These are local forks of NixOS configuration modules.

#### shared/overlays/

These are overlays, in overlay-per-file format suitable for use with `$NIX_PATH`. The actual integration of the overlays into `nixos-rebuild` and `nix-shell` et al is done by `shared/overlays.nix` and `shared/common-nix.nix`.

#### shared/packages/

These are local package definitions. They're included as overlays but can also be built on their own. Some of these are also available in nixpkgs, but the local copy contains local changes (or is there while I wait for nixpkgs to catch up with changes I've upstreamed).

### ancilla/, thoth/, et al

Other top-level directories contain machine-specific configuration. The entry point is usually `<machine>/configuration.nix`.
