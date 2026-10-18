# IESDP

The **Infinity Engine Structures Description Project** documents the file formats,
opcodes, and scripting interfaces of the Infinity Engine. The website is built
with Jekyll and custom Ruby plugins.

[Live website](https://gibberlings3.github.io/iesdp/) ·
[Contributing](CONTRIBUTING.md) · [Development guide](DEVELOPMENT.md)

## Local setup

Install Git, the Ruby version in [.ruby-version](.ruby-version), RubyGems from
[.rubygems-version](.rubygems-version), and the Bundler version under `BUNDLED WITH`
in [Gemfile.lock](Gemfile.lock). Native gems also need a compiler and Make.
See the [development guide](DEVELOPMENT.md) for platform and shell instructions.

From the repository root:

```text
bundle config set --local path vendor/bundle
bundle install
bundle exec jekyll serve --host 127.0.0.1 --incremental
```

Open <http://127.0.0.1:4000/iesdp/>. Jekyll watches for edits; stop it with
**Ctrl+C**. Restart after changing configuration, plugins, or dependencies.

## Validate changes

Stop the preview and run a full build after changing data, collections, shared
templates, or dependencies; incremental builds do not track every dependency.

```text
bundle exec jekyll clean
bundle exec jekyll build --strict_front_matter --trace
bundle exec ruby _tools/check-site.rb _site
```

The checker compares generated action/opcode listings and offsets with source
data, and checks rendering, styles, feeds, UTF-8, and output exclusions. Inspect
the generated pages in a browser, including `_site/index.htm` opened directly
for offline use. The development guide covers
[link comparisons and dependency maintenance](DEVELOPMENT.md#optional-link-comparison).

## Publishing

Work happens on `master`. GitHub Actions builds and checks pull requests and
pushes; successful pushes to `Gibberlings3/iesdp:master` publish the generated
files to `gh-pages`. Fork pushes and manual workflow runs only validate.
The generated branch also provides the downloadable offline archive.

Use the local preview commands for development. `deploy.sh` is CI publishing
machinery and requires repository credentials. See [CONTRIBUTING.md](CONTRIBUTING.md)
for content and data-format conventions.
