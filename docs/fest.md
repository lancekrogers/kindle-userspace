# Festival on a Kindle

[Fest](https://github.com/Obedience-Corp/fest) is public. You can put the
binary on `/mnt/us`. That does **not** mean kindle-userspace should become
a fest fork.

This repo is the pipe (SSH, FAT, git). Fest is a 30 MB planner with a
Charm TUI. Ship the pipe here. Build fest from its own tree.

## What you actually get

Works over SSH, after git is installed:

- `fest version`
- `fest init` (needs git HTTPS, or a copied `$HOME/.obey/fest` cache)
- `fest list`, `fest status`, `fest validate`, `fest next` (markdown out)
- `fgo` / `fest go` via [`scripts/ash-camp.sh`](../scripts/ash-camp.sh)

Leave on the computer:

- `fest create` and the other Bubbletea wizards (e-ink will fight them)
- A full Mac campaign. 1 GB RAM. Do not copy My_Tools.

Fest without [camp](https://github.com/Obedience-Corp/camp) is half a
product. The build script emits both.

## Build on the computer

Needs Go 1.25+. Downloads the public modules. Does not vendor them.

```bash
just pack-fest
# → work/fest-kindlehf.tar.gz   (camp + fest + ash hooks)
```

Pin if you want:

```bash
FEST_VERSION=v0.5.1 CAMP_VERSION=v0.4.0 just pack-fest
```

Or point at a local checkout:

```bash
FEST_DIR=~/src/fest CAMP_DIR=~/src/camp just pack-fest
```

## Install on the Kindle

Git first ([guide](guide.md)). Then:

```bash
scp work/fest-kindlehf.tar.gz kindle:/mnt/us/
ssh kindle 'sh /path/to/install-fest.sh'
```

That puts `camp` and `fest` in `/mnt/us/bin` and sources the ash hooks
from `/mnt/us/.ash_camp`. Proof:

```sh
export PATH=/mnt/us/bin:$PATH
fest version
camp version
```

`fest init` talks to GitHub unless `$HOME/.obey/fest` already exists.
If `git ls-remote` exits 128, run `scripts/wrap-git-https.sh` and retry,
or copy a cache from the computer.

## Why it is not in the tarball by default

`just pack-git` is the userspace people need. Fest is optional, large,
and a different license/release train. Keeping the binary out of this
git tree means we can open kindle-userspace without also shipping a
stale 30 MB `fest` every time Obedience-Corp tags.
