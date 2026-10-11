# IESDP

The **Infinity Engine Structures Description Project** documents the file formats,
opcodes, and scripting interfaces of the Infinity Engine. The website is built
with Jekyll and custom Ruby plugins.

[Live website](https://gibberlings3.github.io/iesdp/) ·
[Contributing](CONTRIBUTING.md)

## Contents

- [Required tools](#required-tools)
- [Operating-system setup](#operating-system-setup)
- [Get the source and install dependencies](#get-the-source-and-install-dependencies)
- [Everyday development](#everyday-development)
- [Clean build and verification](#clean-build-and-verification)
- [Troubleshooting](#troubleshooting)
- [Dependency maintenance](#dependency-maintenance)
- [Publishing and contributing](#publishing-and-contributing)

## Required tools

| Tool | Requirement | Purpose |
| --- | --- | --- |
| Git | Installed and available on `PATH` | Clone the repository and fetch the security advisory database. |
| Ruby | Version in [.ruby-version](.ruby-version) | Run Jekyll and the custom plugins. Use the exact project version. |
| RubyGems | Version in [.rubygems-version](.rubygems-version) | Install and manage Ruby gems; CI reads the same pin. |
| Bundler | `BUNDLED WITH` version in [Gemfile.lock](Gemfile.lock) | Install the project's locked dependencies. |
| C/C++ compiler and Make | Platform tools described below | Build gems with native extensions. A version-manager Ruby includes its development headers. |
| Web browser | A current browser | Inspect the local website. |
| Python 3 | Optional | Run the local link comparison tool. |

Jekyll, WEBrick, the Sass compiler, plugins, and the dependency auditor are installed
by Bundler from [Gemfile](Gemfile). Internet access is needed for initial setup and
security-database updates.

Examples support **Bash, Zsh, and Fish** on Linux, macOS, and WSL, and
**PowerShell** on native Windows. Shared command blocks work in all these shells;
version selection and setup blocks are labeled where syntax differs. Run project
commands from the repository root unless stated otherwise.

The checked-in version files are the source of truth. CI installs those versions;
it does not update the pins simply by running. Reviewed dependency and toolchain
updates change the files, so the commands below read them dynamically.

## Operating-system setup

If you already have a Ruby version manager, keep using it and install the version
in `.ruby-version`. The Linux and macOS recipes below use
[rbenv](https://github.com/rbenv/rbenv) with
[ruby-build](https://github.com/rbenv/ruby-build).

### Linux

**Ubuntu / Debian:** install the compiler and libraries needed to build Ruby and
native gems:

```bash
sudo apt update
sudo apt install -y git curl build-essential autoconf bison pkg-config \
  libssl-dev libyaml-dev zlib1g-dev libffi-dev libgmp-dev \
  libreadline-dev libncurses-dev
```

For Fedora, Arch, and other distributions, install the equivalent packages listed
in ruby-build's [build environment guide](https://github.com/rbenv/ruby-build/wiki#suggested-build-environment),
then use the same rbenv steps below.

Install rbenv and its Ruby installer if they are not already installed:

```bash
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
mkdir -p ~/.rbenv/plugins
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
~/.rbenv/bin/rbenv init
```

Run the initializer from your usual interactive shell; it detects Bash, Zsh, and
Fish and configures that shell's startup file. If you previously configured only
Bash/Zsh, run `~/.rbenv/bin/rbenv init fish` from Fish to configure it too.

Open a new terminal so the shell configuration takes effect. Continue with
[Get the source and install dependencies](#get-the-source-and-install-dependencies).

### macOS

Install Apple's Command Line Tools if needed, and complete the installer before
continuing:

```bash
xcode-select --install
```

Install [Homebrew](https://brew.sh/) if needed. **Fish users:** ensure Homebrew is
available in Fish before continuing. For the standard Apple Silicon or Intel
installation, run the following in Fish and add it to
`~/.config/fish/config.fish` for future terminals:

```fish
if test -x /opt/homebrew/bin/brew
    /opt/homebrew/bin/brew shellenv fish | source
else if test -x /usr/local/bin/brew
    /usr/local/bin/brew shellenv fish | source
end
```

This uses Homebrew's [shell environment setup](https://docs.brew.sh/Manpage#shellenv-shell-).
Then install Git, rbenv, and the Ruby build dependencies in your usual shell:

```bash
brew install git rbenv ruby-build openssl@3 readline libyaml gmp autoconf pkgconf
rbenv init
```

`rbenv init` configures the shell you run it from, including Fish. To add Fish to
an existing Bash/Zsh setup, run `rbenv init fish`.

Open a new terminal, then continue with
[Get the source and install dependencies](#get-the-source-and-install-dependencies).
Use the version-manager Ruby for this project rather than macOS's system Ruby.
This setup applies to both Apple Silicon and Intel Macs.

### Windows

#### Recommended: WSL2 with Ubuntu

WSL2 provides a Linux development environment on Windows and follows the same
build workflow as Linux. In **PowerShell as Administrator**, run:

```powershell
wsl --install
```

Restart Windows if prompted, open **Ubuntu**, and finish its user-account setup.
Follow the [Linux instructions](#linux) and run subsequent commands in the Ubuntu
terminal. Keep the repository in the Linux filesystem, such as `~/src/iesdp`, for
reliable file watching and filesystem performance. Open the local preview in your
normal Windows browser.

See Microsoft's [WSL installation guide](https://learn.microsoft.com/en-us/windows/wsl/install)
if WSL is already installed or requires configuration.

#### Alternative: native Windows with RubyInstaller

1. Install [Git for Windows](https://gitforwindows.org/) and make Git available on
   `PATH`.
2. Read [.ruby-version](.ruby-version) and install the matching **Ruby+Devkit**
   release from [RubyInstaller](https://rubyinstaller.org/downloads/). Use the
   [download archives](https://rubyinstaller.org/downloads/archives/) if the pin
   is older than the releases on the main page. Choose the matching architecture,
   usually **x64**, and enable the installer option to add Ruby to `PATH`.
3. In a fresh PowerShell window, install and enable the development toolchain:

   ```powershell
   ridk install
   ridk enable
   ```

   Select **MSYS2 and MINGW development toolchain** when prompted by `ridk install`.
4. Continue with the common setup below. RubyInstaller supplies the Ruby headers;
   its Devkit supplies the compiler and Make. Run `ridk enable` in later terminals
   when you need those tools.

Jekyll's upstream project does not officially support native Windows. This is an
alternative setup; WSL2 is the preferred Windows workflow for this repository.
Consult the [Jekyll Windows guide](https://jekyllrb.com/docs/installation/windows/)
for platform-specific troubleshooting.

## Get the source and install dependencies

### 1. Check out the repository

If you already have a checkout, open its root directory and skip cloning.
Otherwise, these commands work in Bash, Zsh, Fish, or PowerShell:

```text
git clone https://github.com/Gibberlings3/iesdp.git
cd iesdp
```

On WSL, create and enter a directory such as `~/src` before cloning.

### 2. Select the project Ruby

**Linux, macOS, and WSL with rbenv:**

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

rbenv automatically selects `.ruby-version` inside the checkout. Ruby installation
can take several minutes. If you use another version manager, use its equivalent
installation command.

**Native Windows:** RubyInstaller should already provide the required Ruby.
Confirm it in PowerShell:

```powershell
Get-Content .ruby-version
ruby --version
```

The Ruby version reported by `ruby --version` must match `.ruby-version`.

### 3. Install the locked gems

Install RubyGems and Bundler using the checked-in pins. Choose the block for your
shell; the Ruby one-liner in the Unix examples reads Bundler's version from the
lockfile without requiring Bundler to be installed first.

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

**Native Windows — PowerShell:**

```powershell
$rubyGemsVersion = (Get-Content .rubygems-version -Raw).Trim()
$bundlerVersion = [regex]::Match((Get-Content Gemfile.lock -Raw), '(?m)^BUNDLED WITH\s+(\S+)').Groups[1].Value
gem update --system $rubyGemsVersion --no-document
gem install bundler --version $bundlerVersion --no-document
```

Then run these commands on **all platforms**:

```text
bundle config set --local path vendor/bundle
bundle install
```

Bundler is installed explicitly because its locked version can differ from the
version shipped with RubyGems. Gems are stored locally in the ignored
`vendor/bundle` directory; `.bundle` stores the local configuration.
Use `bundle install` for setup and after pulling dependency changes.

Run project commands through `bundle exec` to select the locked gem versions,
including patched replacements for Ruby's default gems.

Verify the tools:

```text
git --version
gem --version
bundle --version
bundle exec jekyll --version
```

Compare RubyGems with `.rubygems-version`, Bundler with `BUNDLED WITH` in
`Gemfile.lock`, and Jekyll with its resolved entry in that lockfile.
A first installation on a different OS or architecture can add platform entries
to `Gemfile.lock`; review those changes. Keep the lockfile, and reserve
`bundle update` for intentional dependency upgrades.

## Everyday development

Start the local server with incremental rebuilding and automatic browser refresh:

```text
bundle exec jekyll serve --host 127.0.0.1 --incremental --livereload
```

Open **<http://127.0.0.1:4000/iesdp/>**. Keep the terminal running while editing;
Jekyll watches for changes automatically. Press **Ctrl+C** to stop the server.
Generated files are written to `_site`.

`--incremental` speeds up small edits by reusing previous output. The first build
still generates the site. Pages marked `regenerate: true`, including several
large documentation pages in this repository, still rebuild on each run.

> **Before final verification:** stop the server and run the clean-build steps
> below. Jekyll's [incremental dependency tracking](https://jekyllrb.com/docs/configuration/incremental-regeneration/)
> is incomplete, especially for data and collection references. Use a clean build
> after changes to `_data`, `_opcodes`, shared rendering code, or dependencies.
> Restart the server after changing `_config.yml`, `_plugins`, or installed gems.

## Clean build and verification

Stop any running preview first. Choose the block for your shell, and resolve any
command failure before continuing. `jekyll clean` removes generated output and
Jekyll caches; the build deliberately omits `--incremental`.

### Linux, macOS, and WSL — Bash/Zsh/Fish

```sh
env BUNDLE_FROZEN=true bundle install
bundle exec jekyll clean
env JEKYLL_ENV=production bundle exec jekyll build --strict_front_matter --trace
bundle exec jekyll doctor
bundle exec ruby _tools/check-site.rb _site
bundle exec bundle-audit check --update
```

### Native Windows — PowerShell

```powershell
$env:BUNDLE_FROZEN = "true"
bundle install
Remove-Item Env:BUNDLE_FROZEN

bundle exec jekyll clean
$env:JEKYLL_ENV = "production"
bundle exec jekyll build --strict_front_matter --trace
Remove-Item Env:JEKYLL_ENV

bundle exec jekyll doctor
bundle exec ruby _tools/check-site.rb _site
bundle exec bundle-audit check --update
```

The Unix `env` prefix sets flags for one command and works in Bash, Zsh, and Fish.
The PowerShell `Remove-Item` commands clear the temporary flags from that terminal.
The frozen installation checks that setup can be reproduced without changing the
lockfile. The smoke check validates generated action/opcode listings, offset
tables, nested rendering, styles, RSS, sitemap, and output exclusions. The audit
checks the locked gems against the current vulnerability database.

### Inspect the result

Serve the exact output you just built, without rebuilding or watching:

```text
bundle exec jekyll serve --host 127.0.0.1 --skip-initial-build --no-watch
```

Open <http://127.0.0.1:4000/iesdp/> and check the homepage, navigation, action and
opcode listings, file-format tables, images, and deep links. Check a narrow browser
window as well. For offline use, open `_site/index.htm` directly and follow links
into nested documentation pages.

### Optional: compare local links with an earlier build

The link checker uses Python 3's standard library. Preserve a separate build of
the same source revision as your baseline before comparing dependency changes.

**Linux / macOS / WSL — Bash/Zsh/Fish:**

```sh
python3 _tools/check-links.py _site --baseline "/path/to/previous-build"
```

**Native Windows with Python installed:**

```powershell
py -3 _tools/check-links.py _site --baseline "C:\path\to\previous-build"
```

With a baseline, the command fails on newly introduced issues. Without
`--baseline`, it reports all current issues and fails if any are found.

## Troubleshooting

| Symptom | Action |
| --- | --- |
| Wrong Ruby version or gem permission errors | Open the checkout in a fresh, initialized terminal and check `ruby --version`. With rbenv, check `rbenv version`. Install gems using the project Ruby without `sudo`. |
| A native extension cannot compile | Check the platform prerequisites above. On macOS, finish the Command Line Tools installation. On native Windows, run `ridk enable` and confirm the Devkit is installed. |
| Edits do not appear | Stop the preview, run `bundle exec jekyll clean`, and restart. Use the full verification build for data, collection, plugin, or dependency changes. |
| File changes are not detected | Keep WSL checkouts in its Linux filesystem. If needed, append `--force_polling` to the development server command. |
| Port 4000 is already in use | Stop the other preview or append `--port 4001`; then open `http://127.0.0.1:4001/iesdp/`. |
| Browser refresh does not happen automatically | Refresh manually, or run without `--livereload` if its connection is blocked. Incremental rebuilding still works without live reload. |

## Dependency maintenance

Dependency updates are made manually. Scheduled CI runs weekly build and security
checks, and pull requests and pushes are also validated. Review and test dependency
updates before merging them.

For an intentional gem refresh:

```text
bundle update
bundle lock --add-checksums
bundle outdated --strict
```

Then run the clean-build, audit, and browser checks above. `bundle outdated`
without `--strict` also lists newer releases blocked by dependency constraints;
review upstream compatibility before widening those constraints.

Ruby and RubyGems updates remain manual: update `.ruby-version` and
`.rubygems-version`, install that toolchain, and run `bundle update --ruby` with
the selected interpreter. To update Bundler intentionally, use
`bundle update --bundler` and repeat the setup and verification steps. CI reads
the same pins; the README commands adapt without duplicating release numbers.

## Publishing and contributing

Local preview and build commands are the same entry points used for development
and testing. Public deployment is handled by GitHub Actions: successful pushes to
`master` build and validate the site, then publish the generated files to
`gh-pages`. Pull requests and scheduled checks validate without publishing.

`deploy.sh` is CI publishing machinery and requires repository credentials; use
the preview commands above for local work. See the
[contributing guide](CONTRIBUTING.md) for content and data-format conventions.
