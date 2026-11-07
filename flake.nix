{
  description = "IESDP: official development and CI environment";

  # flake.lock pins each input by revision and NAR hash; review that diff
  # whenever the toolchain is updated (see DEVELOPMENT.md).
  inputs = {
    # Everything except hk.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # Used only for hk, which the stable release does not package.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, nixpkgs-unstable, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      # Named explicitly so a change of the nixpkgs `ruby` alias cannot
      # silently change the toolchain. RubyGems and Bundler are the ones
      # shipped with this interpreter.
      rubyFor = pkgs: pkgs.ruby_4_0;

      # Must match the hk schema version in hk.pkl (checked by `hk-schema`).
      hkFor = pkgs: nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.hk;

      # Published hk Pkl schema package that hk.pkl amends. Update these
      # hashes together with the nixpkgs-unstable input (see DEVELOPMENT.md).
      hkSchema = {
        version = "2.8.1";
        metadataHash = "sha256-6LcObNlFIkikxlqf8FDrngg9JFOh4W/+6A3P9K9EzS8=";
        zipHash = "sha256-A37/rQi3plfDHv92vTs1k8uOTMKCpCYRArJUPUfs67U=";
      };
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            (rubyFor pkgs)
            pkgs.python3
            pkgs.git
            pkgs.gnumake
            pkgs.pkg-config
            pkgs.libffi
            pkgs.libyaml
            pkgs.openssl
            pkgs.zlib
            # Git hooks and linters (hk.pkl)
            (hkFor pkgs)
            pkgs.nixfmt
            pkgs.deadnix
            pkgs.actionlint
            pkgs.shellcheck
            pkgs.ruff
          ];

          # Gems are installed by Bundler from Gemfile.lock (verified against
          # its CHECKSUMS) into the ignored vendor/bundle directory.
          BUNDLE_PATH = "vendor/bundle";
          LANG = "C.UTF-8";
          LC_ALL = "C.UTF-8";

          # Keep host Ruby state out of the environment, and point local
          # contributors (not CI) at the git hooks once.
          shellHook = ''
            unset RUBYLIB RUBYOPT GEM_HOME GEM_PATH
            if [ -z "''${CI:-}" ] && ! git config --get hook.hk-pre-commit.command >/dev/null 2>&1; then
              echo "iesdp: git hooks are not installed; run 'hk install' (see DEVELOPMENT.md)." >&2
            fi
          '';
        };
      });

      checks = forAllSystems (pkgs: {
        # Fails when the checked-in version pins drift from the locked toolchain.
        toolchain-pins =
          pkgs.runCommand "iesdp-toolchain-pins"
            {
              nativeBuildInputs = [ (rubyFor pkgs) ];
              # Only the pin files enter the store, not the whole checkout.
              src = pkgs.lib.fileset.toSource {
                root = ./.;
                fileset = pkgs.lib.fileset.unions [
                  ./.ruby-version
                  ./.rubygems-version
                  ./Gemfile.lock
                ];
              };
            }
            ''
              cd "$src"
              fail=0
              pin() { tr -d '\r\n' < "$1"; }
              lock() { sed -n "/^$1/{n;s/^ *\(ruby \)\{0,1\}//;s/\r//;p;}" Gemfile.lock; }
              compare() {
                if [ "$2" = "$3" ]; then
                  echo "ok   $1: $2"
                else
                  echo "FAIL $1: pinned '$2', locked toolchain provides '$3'" >&2
                  fail=1
                fi
              }
              ruby_v=$(ruby -e 'print RUBY_VERSION')
              gem_v=$(gem --version)
              bundler_v=$(bundle --version | sed 's/^Bundler version //')
              compare .ruby-version "$(pin .ruby-version)" "$ruby_v"
              compare "Gemfile.lock RUBY VERSION" "$(lock 'RUBY VERSION')" "$ruby_v"
              compare .rubygems-version "$(pin .rubygems-version)" "$gem_v"
              compare "Gemfile.lock BUNDLED WITH" "$(lock 'BUNDLED WITH')" "$bundler_v"
              if [ "$fail" -ne 0 ]; then
                echo "Update the pins to match flake.lock; see DEVELOPMENT.md (Toolchain updates)." >&2
                exit 1
              fi
              touch "$out"
            '';

        # Fails when hk.pkl, the hk binary, and the pinned schema package
        # disagree, or when the published package no longer matches its hashes.
        hk-schema =
          let
            base = "https://github.com/jdx/hk/releases/download/v${hkSchema.version}/hk@${hkSchema.version}";
            metadata = pkgs.fetchurl {
              url = base;
              hash = hkSchema.metadataHash;
            };
            zip = pkgs.fetchurl {
              url = "${base}.zip";
              hash = hkSchema.zipHash;
            };
          in
          pkgs.runCommand "iesdp-hk-schema"
            {
              nativeBuildInputs = [
                (hkFor pkgs)
                pkgs.jq
              ];
            }
            ''
              set -eu
              want=${hkSchema.version}
              hk_v=$(hk --version | cut -d' ' -f2)
              [ "$hk_v" = "$want" ] || { echo "FAIL hk binary is $hk_v, schema pin is $want" >&2; exit 1; }
              used=$(grep -oE 'hk@[0-9.]+#' ${./hk.pkl} | sort -u | tr -d '#')
              [ "$used" = "hk@$want" ] || { echo "FAIL hk.pkl uses '$used', expected hk@$want" >&2; exit 1; }
              zip_sha=$(sha256sum ${zip} | cut -d' ' -f1)
              meta_sha=$(jq -r '.packageZipChecksums.sha256' ${metadata})
              [ "$zip_sha" = "$meta_sha" ] || { echo "FAIL package metadata does not pin the verified zip" >&2; exit 1; }
              echo "ok   hk $hk_v, hk.pkl hk@$want, package zip sha256 $zip_sha"
              touch "$out"
            '';
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt);
    };
}
