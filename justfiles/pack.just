# FAT-safe musl packs. Default lists this module.

[private]
default:
    @just --list --justfile {{ source_file() }}

# Alpine musl/armv7 git → work/git-kindlehf.tar.gz
git:
    {{ justfile_directory() }}/../scripts/pack-musl-git.sh

# Alpine musl/armv7 vim → work/vim-kindlehf.tar.gz
vim:
    {{ justfile_directory() }}/../scripts/pack-musl-vim.sh
