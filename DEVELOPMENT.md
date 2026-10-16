# Development setup and maintenance

The [README](README.md) covers the everyday preview and validation commands.
This guide adds platform setup, shell-specific toolchain installation,
troubleshooting, and optional maintenance. Run project commands from the
repository root unless stated otherwise.

## Platform prerequisites

Use the exact Ruby version in [.ruby-version](.ruby-version). If you already have
a Ruby version manager, keep using it. The examples below use
[rbenv](https://github.com/rbenv/rbenv) and
[ruby-build](https://github.com/rbenv/ruby-build) on Linux, macOS, and WSL.

### Linux

On Ubuntu or Debian, install the tools and libraries needed to compile Ruby and
native gems:

```bash
sudo apt update
sudo apt install -y git curl build-essential autoconf bison pkg-config \
  libssl-dev libyaml-dev zlib1g-dev libffi-dev libgmp-dev \
  libreadline-dev libncurses-dev
```

For other distributions, use ruby-build's
[build environment guide](https://github.com/rbenv/ruby-build/wiki#suggested-build-environment).
If rbenv and ruby-build are not already installed:

```bash
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
mkdir -p ~/.rbenv/plugins
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
~/.rbenv/bin/rbenv init
```

Run the initializer from your usual interactive shell and open a fresh terminal.
It supports Bash, Zsh, and Fish. To add Fish to an existing setup, run
`~/.rbenv/bin/rbenv init fish`.

### macOS

Install Apple's Command Line Tools, complete the installer, then install
[Homebrew](https://brew.sh/) if needed:

```bash
xcode-select --install
```

With Homebrew available in your shell:

```bash
brew install git rbenv ruby-build openssl@3 readline libyaml gmp autoconf pkgconf
rbenv init
```

Open a fresh terminal. Use the version-manager Ruby rather than macOS's system
Ruby. This applies to both Apple Silicon and Intel Macs.

For Fish, initialize Homebrew in `~/.config/fish/config.fish`:

```fish
if test -x /opt/homebrew/bin/brew
    /opt/homebrew/bin/brew shellenv fish | source
else if test -x /usr/local/bin/brew
    /usr/local/bin/brew shellenv fish | source
end
```

Run that block in the current Fish terminal before the `brew install` command.
`rbenv init` configures the shell it runs from; use `rbenv init fish` to add Fish
to an existing setup. See Homebrew's
[shell environment documentation](https://docs.brew.sh/Manpage#shellenv-shell-).

### Windows

**WSL2 with Ubuntu is the preferred setup.** In PowerShell as Administrator:

```powershell
wsl --install
```

Restart if prompted, finish Ubuntu's account setup, and follow the Linux steps
inside Ubuntu. Keep the checkout in the Linux filesystem, such as `~/src/iesdp`.
Use your normal Windows browser for the preview. See Microsoft's
[WSL installation guide](https://learn.microsoft.com/en-us/windows/wsl/install).

For native Windows, install [Git for Windows](https://gitforwindows.org/) and the
**Ruby+Devkit** release matching `.ruby-version` from
[RubyInstaller](https://rubyinstaller.org/downloads/), using its
[archives](https://rubyinstaller.org/downloads/archives/) when needed. Choose the
matching architecture, usually x64, and add Ruby to `PATH`. In a new PowerShell:

```powershell
ridk install
ridk enable
```

Select **MSYS2 and MINGW development toolchain** when prompted. Run `ridk enable`
in later terminals when compiling native gems. Jekyll does not officially
support native Windows; consult its
[Windows guide](https://jekyllrb.com/docs/installation/windows/) for troubleshooting.

## Install the project toolchain

If needed, clone the repository and enter its root:

```text
git clone https://github.com/Gibberlings3/iesdp.git
cd iesdp
```

### Select Ruby

With rbenv, install the version selected automatically by `.ruby-version`.

**Bash / Zsh:**

```bash
rbenv install -s "$(cat .ruby-version)"
ruby --version
```

**Fish:**

```fish
rbenv install -s (string trim < .ruby-version)
ruby --version
```

On native Windows, confirm RubyInstaller supplied the required version:

```powershell
Get-Content .ruby-version
ruby --version
```

### Install RubyGems, Bundler, and gems

Read RubyGems from `.rubygems-version` and Bundler from `Gemfile.lock` so setup
and CI use the same pins. Internet access is required for initial installation.

**Bash / Zsh:**

```bash
rubygems_version=$(tr -d '\r\n' < .rubygems-version)
bundler_version=$(ruby -e 'puts File.read("Gemfile.lock")[/^BUNDLED WITH\s+(\S+)/, 1]')
gem update --system "$rubygems_version" --no-document
gem install bundler --version "$bundler_version" --no-document
```

**Fish:**

```fish
set -l rubygems_version (string trim < .rubygems-version)
set -l bundler_version (ruby -e 'puts File.read("Gemfile.lock")[/^BUNDLED WITH\s+(\S+)/, 1]')
gem update --system "$rubygems_version" --no-document
gem install bundler --version "$bundler_version" --no-document
```

**PowerShell:**

```powershell
$rubyGemsVersion = (Get-Content .rubygems-version -Raw).Trim()
$bundlerVersion = [regex]::Match((Get-Content Gemfile.lock -Raw), '(?m)^BUNDLED WITH\s+(\S+)').Groups[1].Value
gem update --system $rubyGemsVersion --no-document
gem install bundler --version $bundlerVersion --no-document
```

Then, on every platform:

```text
bundle config set --local path vendor/bundle
bundle install
gem --version
bundle --version
bundle exec jekyll --version
```

Gems and local configuration live in the ignored `vendor/bundle` and `.bundle`
directories. Use `bundle exec` for project commands and `bundle install` after
pulling dependency changes. Review any lockfile platform additions on a new OS
or architecture; reserve `bundle update` for intentional upgrades.

## Verification and troubleshooting

Before the README's full-build checks, verify installation with the lockfile
frozen, as CI does.

**Bash / Zsh / Fish:**

```sh
env BUNDLE_FROZEN=true bundle install
```

**PowerShell:**

```powershell
$env:BUNDLE_FROZEN = "true"
bundle install
Remove-Item Env:BUNDLE_FROZEN
```

Stop at any command failure. After a full build, serve the exact generated files
without rebuilding:

```text
bundle exec jekyll serve --host 127.0.0.1 --skip-initial-build --no-watch
```

Inspect navigation, action/opcode listings, offset tables, images, and deep
links at <http://127.0.0.1:4000/iesdp/>, including a narrow browser window.
Open `_site/index.htm` directly and follow nested links to check offline use.

| Symptom | Action |
| --- | --- |
| Wrong Ruby version or gem permission errors | Check `ruby --version` and `rbenv version` in a fresh, initialized terminal. Install gems with the project Ruby without `sudo`. |
| Native extension compilation fails | Check the platform prerequisites. Finish Command Line Tools installation on macOS; run `ridk enable` on native Windows. |
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

On native Windows:

```powershell
py -3 _tools/check-links.py _site --baseline "C:\path\to\previous-build"
```

With a baseline, the command fails only on newly introduced issues. Without
`--baseline`, it reports all current issues and fails if any are found.

## Manual dependency maintenance

Dependencies and toolchain pins are updated manually. CI validates pushes, pull
requests, and manual runs; it does not schedule audits or update dependencies.

For an intentional gem refresh:

```text
bundle update
bundle lock --add-checksums
bundle outdated --strict
```

Run the full build, documentation checks, link comparison, and browser checks.
`bundle outdated` without `--strict` also lists releases outside current
constraints; review upstream compatibility before widening them.

An optional local audit checks locked gems against current advisories. It needs
Git and network access to update its advisory database:

```text
bundle exec bundle-audit check --update
```

For Ruby or RubyGems updates, edit `.ruby-version` or `.rubygems-version`, install
that toolchain, and run `bundle update --ruby` with the selected interpreter.
For Bundler, use `bundle update --bundler`. Repeat installation and validation
after any toolchain update; CI reads the checked-in pins.
