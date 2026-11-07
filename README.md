# IESDP

The **Infinity Engine Structures Description Project** documents the file formats,
opcodes, and scripting interfaces of the Infinity Engine. The website is built
with Jekyll and custom Ruby plugins.

[Live website](https://gibberlings3.github.io/iesdp/) ·
[Contributing](CONTRIBUTING.md) · [Development guide](DEVELOPMENT.md)

## Local setup

The official development environment is the [Nix](https://nixos.org/) flake in
[flake.nix](flake.nix), locked by [flake.lock](flake.lock). CI uses the same
environment. It supports Linux and macOS (x86_64 and ARM), and Windows through
WSL2. Install Nix with flakes enabled as described in the
[development guide](DEVELOPMENT.md#nix-environment), then, from the repository root:

```sh
nix develop
hk install          # once per clone: git hooks and linters
bundle install
bundle exec jekyll serve --host 127.0.0.1 --incremental
```

Open <http://127.0.0.1:4000/iesdp/>. Jekyll watches for edits; stop it with
**Ctrl+C**. Restart after changing configuration, plugins, or dependencies.
The development guide also covers [setup without Nix](DEVELOPMENT.md#setup-without-nix).

## Validate changes

Stop the preview and run a full build after changing data, collections, shared
templates, or dependencies; incremental builds do not track every dependency.
Inside `nix develop`:

```sh
bundle exec jekyll clean
bundle exec jekyll build --strict_front_matter --trace
bundle exec ruby _tools/check-site.rb _site
```

The checker compares generated action/opcode listings and offsets with source
data, and checks rendering, styles, feeds, UTF-8, and output exclusions. Inspect
the generated pages in a browser, including `_site/index.htm` opened directly
for offline use. Run `hk check --all` for the linters ([hk.pkl](hk.pkl)), and
`nix flake check` after changing the flake, toolchain pins, or hk version. The
development guide covers [the full CI sequence](DEVELOPMENT.md#reproduce-ci-locally),
[git hooks and linters](DEVELOPMENT.md#git-hooks-and-linters),
[link comparisons](DEVELOPMENT.md#optional-link-comparison), and
[dependency maintenance](DEVELOPMENT.md#dependency-and-toolchain-maintenance).

## Publishing

Work happens on `master`. GitHub Actions builds and checks pull requests and
pushes in the Nix environment; successful pushes to `Gibberlings3/iesdp:master`
publish the generated files to `gh-pages`. Fork pushes and manual workflow runs
only validate. The generated branch also provides the downloadable offline archive.

Use the local preview commands for development. `deploy.sh` is CI publishing
machinery and requires repository credentials. See [CONTRIBUTING.md](CONTRIBUTING.md)
for content and data-format conventions.
