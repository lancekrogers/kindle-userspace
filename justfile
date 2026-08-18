# kindle-userspace — pack helpers for a jailbroken Kindle userstore

set dotenv-load := false

mod pack 'justfiles/pack.just'

[private]
default:
    @just --list --justfile {{ source_file() }}

# FAT-safe musl git tree → work/git-kindlehf.tar.gz
pack-git:
    ./scripts/pack-musl-git.sh

# FAT-safe musl vim tree → work/vim-kindlehf.tar.gz
pack-vim:
    ./scripts/pack-musl-vim.sh

# Public camp+fest linux/arm → work/fest-kindlehf.tar.gz
pack-fest:
    ./scripts/pack-fest.sh

# Show what this repo is
about:
    @echo "kindle-userspace — run your own programs on hardware you own"
    @echo "Scripts live in scripts/. Do not commit device serials, keys, or JB payloads."

# Confirm pack/install scripts are executable and work/ is ignored
check:
    test -x scripts/pack-musl-git.sh
    test -x scripts/pack-musl-vim.sh
    test -x scripts/install-git.sh
    test -x scripts/install-vim.sh
    test -x scripts/wrap-git-https.sh
    test -x scripts/start-ssh.sh
    test -x scripts/ash-camp.sh
    test -x scripts/build-go.sh
    test -x scripts/pack-fest.sh
    test -x scripts/install-fest.sh
    test -f .gitignore
    grep -q '^work/$' .gitignore
    grep -q '\.azw3' .gitignore
    @echo "ok"
