# Development setup and maintenance

The [README](README.md) covers the everyday preview and validation commands.
This guide covers the official Nix environment, git hooks and linters,
reproducing CI locally, troubleshooting, setup without Nix, and maintenance. Run project commands from
the repository root unless stated otherwise.

## Nix environment

[flake.nix](flake.nix) defines the official toolchain for local development and
CI. It has two inputs, both pinned by revision and content hash in
[flake.lock](flake.lock): `nixpkgs` (the `nixos-26.05` release) for everything,
and `nixpkgs-unstable`, used only for [hk](https://hk.jdx.dev), which the release
does not package. Supported systems are `x86_64-linux`, `aarch64-linux`,
`x86_64-darwin`, and `aarch64-darwin`. CI exercises `x86_64-linux`; the other
systems are evaluated by `nix flake check` but are not run in CI. nixpkgs 26.05
is the last release that supports `x86_64-darwin`, so Intel Macs lose support
when the flake moves to a later nixpkgs release.

The development shell provides:

- Ruby from nixpkgs (`ruby_4_0`) with the RubyGems and Bundler that ship with it
- Python 3 for `_tools/check-links.py`, and Git
- hk and the linters it runs: `nixfmt`, `deadnix`, `actionlint`, `shellcheck`,
  and `ruff` (see [Git hooks and linters](#git-hooks-and-linters))
- a C/C++ compiler, Make, `pkg-config`, and the libraries native gems link against
- `BUNDLE_PATH=vendor/bundle` and a UTF-8 locale. The shell also unsets
  `RUBYLIB`, `RUBYOPT`, `GEM_HOME`, and `GEM_PATH` so a host Ruby setup cannot
  leak in.

Gems are not managed by Nix. Bundler installs them from [Gemfile.lock](Gemfile.lock)
into the ignored `vendor/bundle` directory and verifies each against the
lockfile's `CHECKSUMS`. The shell never touches the network on its own; it only
prints a reminder when the git hooks are not installed.

### Install Nix

Use the official multi-user installer on Linux, macOS, or WSL2 (see
[the Nix download page](https://nixos.org/download/)):

```sh
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
```

Open a new terminal and enable flakes in `~/.config/nix/nix.conf`, or in
`/etc/nix/nix.conf` for all users:

```text
experimental-features = nix-command flakes
```

On NixOS, set `nix.settings.experimental-features = [ "nix-command" "flakes" ];`
instead.

**Windows:** install WSL2 with Ubuntu from an Administrator PowerShell
(`wsl --install`), then follow the Linux steps inside Ubuntu. Keep the checkout
in the Linux filesystem, such as `~/src/iesdp`, and use your normal Windows
browser for the preview. See Microsoft's
[WSL installation guide](https://learn.microsoft.com/en-us/windows/wsl/install).

**NixOS hosts:** the precompiled `sass-embedded` gem ships a Dart runtime that
expects a standard Linux dynamic loader. Enable `programs.nix-ld.enable = true;`
in your NixOS configuration. Other Linux distributions, macOS, and WSL need nothing extra.

### Enter the environment

```sh
nix develop          # interactive shell
bundle install
```

To run a single command without an interactive shell, prefix it with
`nix develop --command`, as CI does. [direnv](https://direnv.net/) users with
[nix-direnv](https://github.com/nix-community/nix-direnv) can run `direnv allow`
once; the checked-in [.envrc](.envrc) then loads the shell on `cd`. direnv is
optional.

## Git hooks and linters

[hk.pkl](hk.pkl) configures [hk](https://hk.jdx.dev) git hooks and linters. All
the tools come from the dev shell. Install the hooks once per clone, from inside
`nix develop`:

```sh
hk install
```

The `pre-commit` hook then checks staged files and fixes what it can before each
commit. It runs only for commits made from inside the dev shell (or a
direnv-loaded directory): hk installs config-based hooks, which need Git 2.54 or
later, and the linters exist only in the shell. The shell provides a recent
enough Git.

| Scope | Steps |
| --- | --- |
| Whole repository | merge-conflict markers, case conflicts, byte order marks, mixed line endings, executables without shebangs |
| Tooling and project docs only | trailing whitespace, final newline |
| `flake.nix` | `nixfmt`, `deadnix` |
| `.github/workflows` | `actionlint` (which also runs `shellcheck` on `run:` blocks) |
| Shell scripts | `shellcheck`; `cleaner` and `_tools/prepare-ops.sh` are historical one-off migration scripts and are excluded |
| `_tools/check-links.py` | `ruff check`, `ruff format` |

Whitespace rules skip content pages and data (`_data`, `_opcodes`, `files`, and
others), where whitespace inside `<pre>` tables can be significant. "Tooling"
means the paths listed in `hk.pkl`.

Common commands:

```sh
hk check --all                            # what CI runs
hk fix --all                              # apply available fixes
hk check --all --no-fail-fast             # report every failing step
HK_SKIP_STEPS=shellcheck git commit ...   # skip a step once
hk validate                               # check hk.pkl itself
```

hk downloads its pinned Pkl schema package from the hk GitHub release the first
time it runs, then caches it. The `hk-schema` flake check
[verifies that package](#git-hooks-and-linters-updates).

### Reproduce CI locally

This is the sequence the [CI workflow](.github/workflows/updater.yml) runs, minus
publishing:

```sh
nix flake check --print-build-logs
nix develop --command sh -c 'command -v ruby gem bundle python3 hk; ruby --version; gem --version; bundle --version; hk --version'
nix develop --command hk check --all
nix develop --command env BUNDLE_FROZEN=true bundle install
nix develop --command bundle exec jekyll clean
nix develop --command bundle exec jekyll build --strict_front_matter --trace
nix develop --command bundle exec ruby _tools/check-site.rb _site
```

`nix flake check` runs two checks:

- `toolchain-pins` fails if `.ruby-version`, `.rubygems-version`, or the
  `Gemfile.lock` `RUBY VERSION` and `BUNDLED WITH` entries differ from what the
  locked Ruby provides.
- `hk-schema` fails if the hk binary, the schema version in `hk.pkl`, and the
  pinned schema package disagree. It also fails if the published package no
  longer matches the hashes pinned in `flake.nix`.

Formatting and linting of `flake.nix` run through hk (`hk check --all`). `nix fmt`
formats it directly.

Stop at any command failure. After a full build, serve the exact generated files
without rebuilding:

```sh
bundle exec jekyll serve --host 127.0.0.1 --skip-initial-build --no-watch
```

Inspect navigation, action/opcode listings, offset tables, images, and deep
links at <http://127.0.0.1:4000/iesdp/>, including a narrow browser window.
Open `_site/index.htm` directly and follow nested links to check offline use.

## Troubleshooting

| Symptom | Action |
| --- | --- |
| `experimental Nix feature 'nix-command' is disabled` or `'flakes' is disabled` | Enable flakes as described under [Install Nix](#install-nix), or pass `--extra-experimental-features 'nix-command flakes'`. |
| Commits skip the hooks | Install them with `hk install` inside `nix develop`, and commit from inside the shell or a direnv-loaded directory. A system Git older than 2.54 ignores hk's config-based hooks. |
| A hook step reports `command not found` | The commit ran outside the dev shell. Commit from inside `nix develop`. |
| `hk-schema` check fails | hk, `hk.pkl`, and the pinned package disagree. Follow [Git hooks and linters updates](#git-hooks-and-linters-updates). |
| hk cannot load `hk.pkl` while offline | The schema package is not cached yet. Run any hk command once with network access. |
| `toolchain-pins` check fails | The text pins and `flake.lock` disagree. Follow [Toolchain updates](#toolchain-updates); do not edit only one side. |
| Gem load errors or native extension mismatches after a Ruby update | Delete the stale gems with `rm -rf vendor/bundle`, then run `bundle install` again. |
| `sass-embedded` fails to start on NixOS | Enable `programs.nix-ld` (see [Install Nix](#install-nix)). |
| `check-site.rb` reports JSON/REXML version mismatches | Something set `RUBYLIB`; run inside `nix develop`, which clears it. |
| Edits do not appear | Stop the preview, run `bundle exec jekyll clean`, and restart. Incremental tracking is incomplete for data and collections. |
| File changes are not detected | Keep WSL checkouts in its Linux filesystem. Try the preview's `--force_polling` option if needed. |
| Port 4000 is busy | Stop the other preview or use `--port 4001` and open `http://127.0.0.1:4001/iesdp/`. |

The preview can optionally use `--livereload` for browser refresh. Pages marked
`regenerate: true` still rebuild on every incremental run. See Jekyll's
[incremental regeneration documentation](https://jekyllrb.com/docs/configuration/incremental-regeneration/).

## Optional link comparison

The link checker uses Python 3's standard library. Preserve a separate full
build before changing dependencies, then compare the new output with it:

```sh
python3 _tools/check-links.py _site --baseline "/path/to/previous-build"
```

With a baseline, the command fails only on newly introduced issues. Without
`--baseline`, it reports all current issues and fails if any are found.

## Setup without Nix

This path is not supported or tested in CI. Use it only if you cannot use Nix.
You must match the same pins: the Ruby version in [.ruby-version](.ruby-version),
RubyGems from [.rubygems-version](.rubygems-version), and the Bundler version
under `BUNDLED WITH` in [Gemfile.lock](Gemfile.lock). Native gems also need a
compiler and Make.

- **Linux / WSL / macOS:** use a Ruby version manager such as
  [rbenv](https://github.com/rbenv/rbenv) with
  [ruby-build](https://github.com/rbenv/ruby-build), and install that tool's
  [build prerequisites](https://github.com/rbenv/ruby-build/wiki#suggested-build-environment).
  Run `rbenv install -s "$(cat .ruby-version)"`.
- **Native Windows:** install the **Ruby+Devkit** release matching
  `.ruby-version` from [RubyInstaller](https://rubyinstaller.org/downloads/)
  (see its [archives](https://rubyinstaller.org/downloads/archives/)), then run
  `ridk install` and `ridk enable`. Jekyll does not officially support native
  Windows; see its [Windows guide](https://jekyllrb.com/docs/installation/windows/).

Then install the pinned RubyGems and Bundler, and the gems:

```sh
gem update --system "$(tr -d '\r\n' < .rubygems-version)" --no-document
gem install bundler --no-document --version "$(ruby -e 'puts File.read("Gemfile.lock")[/^BUNDLED WITH\s+(\S+)/, 1]')"
bundle config set --local path vendor/bundle
bundle install
```

In PowerShell, read the pins with `(Get-Content .rubygems-version -Raw).Trim()`
and `[regex]::Match((Get-Content Gemfile.lock -Raw), '(?m)^BUNDLED WITH\s+(\S+)').Groups[1].Value`.

## Dependency and toolchain maintenance

Dependencies, toolchain pins, and linters are updated manually, inside `nix develop`. CI
validates pushes, pull requests, and manual runs; it does not schedule audits or
update dependencies.

### Toolchain updates

`flake.lock` is the source of truth for Ruby, RubyGems, and Bundler. To update:

1. `nix flake update nixpkgs`. To move to a newer release, first edit the
   `nixpkgs` branch and, if needed, the `ruby_4_0` attribute in `flake.nix`.
2. Read the new versions with
   `nix develop --command sh -c 'ruby -e "puts RUBY_VERSION"; gem --version; bundle --version'`.
3. Write the Ruby version to `.ruby-version` and the RubyGems version to
   `.rubygems-version`.
4. `rm -rf vendor/bundle`, then inside `nix develop` run `bundle update --ruby`
   and `bundle update --bundler="<new Bundler version>"`. Then run
   `bundle lock --add-checksums` and `bundle install`.
5. `nix flake check` and the full [CI sequence](#reproduce-ci-locally), plus a
   [link comparison](#optional-link-comparison) against a build from before the update.

In the pull request, review the `flake.lock` diff (`rev`, `narHash`,
`lastModified`). Check that the `Gemfile.lock` diff changes only the toolchain
entries unless you also meant to update gems.

### Git hooks and linters updates

hk comes from `nixpkgs-unstable`, and `hk.pkl` must amend the schema package for
the same hk version:

1. `nix flake update nixpkgs-unstable`, then read the new version with
   `nix develop --command hk --version`.
2. In `hk.pkl`, change both `hk@<version>` package URIs and `min_hk_version`.
3. In `flake.nix`, update `hkSchema.version` and its two hashes:

   ```sh
   v=<version>
   nix store prefetch-file --json "https://github.com/jdx/hk/releases/download/v$v/hk@$v" | jq -r .hash
   nix store prefetch-file --json "https://github.com/jdx/hk/releases/download/v$v/hk@$v.zip" | jq -r .hash
   ```

4. `nix flake check`, then `hk check --all`. Review new findings from updated
   linters (`nixfmt`, `ruff`, and others) before you accept fixes.

hk 2.8.1's embedded Pkl evaluator cannot verify `::sha256:` checksums in package
URIs, so `hk.pkl` pins the version only, and `hk-schema` verifies the package.
Revisit this when moving to a newer hk.

### Gem updates

For an intentional gem refresh:

```sh
bundle update
bundle lock --add-checksums
bundle outdated --strict
```

Run the full build, documentation checks, link comparison, and browser checks.
`bundle outdated` without `--strict` also lists releases outside current
constraints; review upstream compatibility before widening them. The lockfile
lists platforms for every supported system (`x86_64-linux`,
`aarch64-linux-gnu`, `x86_64-darwin`, `arm64-darwin`, and the generic `ruby`
platform). Keep them when updating, so precompiled native gems resolve everywhere.

An optional local audit checks locked gems against current advisories. It needs
Git and network access to update its advisory database:

```sh
bundle exec bundle-audit check --update
```
