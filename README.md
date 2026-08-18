# kindle-userspace

Amazon still boots the Kindle. After a public jailbreak you can still run
your own programs on the userstore.

This repo is the toolkit I want to publish: MTP helpers, a Wi-Fi SSH
scriptlet that does not trap the UI, FAT-safe git and vim packs, and POSIX
ash hooks for camp/fest. It is **not** a jailbreak. It does **not** ship
hotfix books, firmware dumps, or DRM tools.

Tested on a first-gen Kindle Scribe, firmware **5.19.5**, hard-float
**kindlehf** (firmware ≥ 5.16.3). Kernel 4.9, glibc 2.35, `armv7l`.

## What you need

- A Kindle you already jailbroke. On 5.17.1–5.19.6 that is currently
  **Véra** (Ava / sparklerfish, August 2026). I will not unpack those
  books here.
- **KPM**, not KUAL. KUAL is dead on ≥ 5.19.4. Véra does not ship MRPI.
  `;log mrpi` printing `mrpi is not installed` is normal.
- Calibre (`calibre-debug`), OpenSSH, `curl`, `tar`.
- The Kindle on a Wi-Fi you can reach from the computer.

You will end with files you own under `/mnt/us`, library books that run
shell, `ssh root@kindle` after you start dropbear, and optionally
`git 2.47.3` / `vim 9.1`.

You will **not** get a custom kernel. `otaup` still checks RSA-SHA256
against `/etc/uks/pubprodkey0{1,2}.pem`.

```text
L0  Open your own files
L1  Run our userspace          ← this repo
L2  Replace Amazon daemons
L4  Our kernel                 ← still signed
```

## One filesystem fact

`/mnt/us` (Internal Storage) is **FAT**. No symlinks. No hardlinks.
`chmod +x` is mostly theater.

- A normal Alpine miniroot will not extract.
- `cp -a` of a tree full of symlinks will not work.
- `mount --bind /mnt/us` or `/proc` into a directory on `/mnt/us`, then
  `rm -rf` that directory, **deletes the library**. Jailbreak hotfix on
  rootfs can survive. Books on the userstore do not.

Put payloads as regular files. Flatten packages on the computer first.

## 1. Build

Static Go CLI (no GTK, no FBInk):

```bash
./scripts/build-go.sh ./myapp-kindlehf ./cmd/myapp
# ELF 32-bit LSB executable, ARM, EABI5, statically linked
```

That is `CGO_ENABLED=0 GOOS=linux GOARCH=arm GOARM=7`. Not `darwin`.
Not `arm64`. Kernel 4.9 is new enough for current Go. Static means you
do not care about soft-float vs hard-float libc.

A real e-ink UI (notes, full screen) is **koxtoolchain +
[kindle-sdk](https://github.com/KindleModding/kindle-sdk)**, target
`kindlehf`, Meson, FBInk/GTK. Walkthrough:
[kindlemodding.org/kindle-dev/gtk-tutorial](https://kindlemodding.org/kindle-dev/gtk-tutorial/).

Do not launch a 20+ MB Charm TUI from a library book.

## 2. Stage over MTP

USB ID `1949:9981`. Calibre `ebook-device` flakes. Use the driver, and
**quit the Calibre GUI first** (MTP is single-client on macOS):

```bash
calibre-debug -e scripts/mtp-put-dir.py -- ./myapp-kindlehf bin myapp
calibre-debug -e scripts/mtp-put-dir.py -- ./scripts/start-ssh.sh documents Start-SSH.sh
```

Do not full-scan the store. Aggressive MTP loops have white-screened a
Scribe here; 40 second power hold.

| Path | Role |
|------|------|
| `/mnt/us/documents/*.sh` | Scriptlets (library books) |
| `/mnt/us/usbnetlite/` | dropbear + `usbnetwork` (regular files) |
| `/mnt/us/bin/` | Your CLIs, `git`, `start-ssh` |
| `/mnt/us/opt/git/` | Flattened musl git |
| `/mnt/us/opt/vim/` | Flattened musl vim |
| `/mnt/us/koreader/` | KPM payload |
| `/mnt/us/mrpackages/*.bin` | **Only** place for unsigned update bins |

A `.bin` on the **storage root** is how official OTA starts. That is how
you lose the jailbreak.

## 3. Scriptlets

`/mnt/us/documents/Something.sh` with `# Name:` / `# Author:` shows up
as a book. After the jailbreak, tap runs it as root. stdout goes to
FBInk unless `# DontUseFBInk`.

```sh
#!/bin/sh
# Name: Hello Userspace
# Author: lab

echo "=== starting ==="
echo DONE
```

Keep it short. Copy files, chmod, print DONE. If you `exec` a 22 MB Go
binary from the book, the UI hangs and you get no log. New `.sh` files
sometimes need a restart to appear. Search the library by name.

KPM installs packages: `;kpm update`, `;kpm install koreader`. A
`KOReader.sh` launcher without the `koreader/` tree does nothing useful.

## 4. Wi-Fi SSH (do not tap Toggle USBNet)

USBNetLite (khf / libcrypt.so.2) is the Scribe-correct dropbear package.
Upstream: [notmarek/kindle-usbnetlite](https://github.com/notmarek/kindle-usbnetlite).
khf rebuild: [MobileRead 369990](https://www.mobileread.com/forums/showthread.php?t=369990)
(`Update_usbnetlite_1.2.4_install_khf.bin`).

Unpack the `.bin` **on the computer**. MTP the extracted files into
`/mnt/us/usbnetlite/bin/` (`dropbearmulti`, `usbnetwork`, …). Do not ask
the Kindle to `tar`/`xz` if you can avoid it.

**Do not tap Toggle USBNet.** That script calls volumd
`useUsbForNetwork 1`, puts the device on a USB-ethernet page, and the
only reliable exit is power off.

This repo’s scriptlet starts dropbear on **wlan0 only**:

```sh
# copy to /mnt/us/documents/Start-SSH.sh and /mnt/us/bin/start-ssh
# first login (password still on):
ALLOW_PASSWORD=true /mnt/us/bin/start-ssh
# after your key is in /mnt/us/.ssh/authorized_keys, default is key-only:
/mnt/us/bin/start-ssh
```

Dropbear is started as:

```text
dropbear -R -H /mnt/us -p 22 -K 15 -s
```

`-R` generates host keys. `-H /mnt/us` makes `authorized_keys`
`/mnt/us/.ssh/authorized_keys`. `-s` disables password. After every
reboot you have to start it again.

On the computer:

```sshconfig
Host kindle
  HostName YOUR_KINDLE_IP
  User root
  IdentityFile ~/.ssh/id_kindle
  IdentitiesOnly yes
  StrictHostKeyChecking accept-new
  HostKeyAlgorithms +ssh-rsa
  PubkeyAcceptedAlgorithms +ssh-rsa,ssh-ed25519
```

`accept-new` still **rejects a rotated key**. After a wipe or a clean
`dropbear -R`:

```bash
ssh-keygen -R YOUR_KINDLE_IP
ssh kindle
```

`Connection refused` means dropbear is not running (normal after
reboot). `Connection closed` during KEX was a wedged dropbear here; kill
it and run `start-ssh`, do not tap Toggle.

USB gadget (`192.168.15.244` on the Kindle, `192.168.15.201` on the
Mac’s RNDIS interface) is optional and **kills MTP** while it is on.
KOReader → Tools → More tools → SSH is a backup.

## 5. Git on FAT

Debian armhf `git` drags half of gnutls. Alpine-in-chroot wants binds.
Both are the wrong first move.

Working recipe: Alpine 3.21 musl/armv7 **git 2.47.3**, flattened, no
chroot.

```bash
just pack-git
# → work/git-kindlehf.tar.gz
scp work/git-kindlehf.tar.gz kindle:/mnt/us/
ssh kindle 'sh /mnt/us/path/to/install-git.sh'
```

`scripts/pack-musl-git.sh` downloads the APKs, copies each `DT_NEEDED`
soname as a regular file (including `ld-musl-armhf.so.1` **and** the
same bytes as `libc.musl-armv7.so.1`), copies only regular files from
`git-core` (do not dereference the 141 copies of `git`), and refuses to
pack if any symlink remains.

`scripts/install-git.sh` unpacks to `/mnt/us/opt/git` and installs
`/mnt/us/bin/git`. Then `scripts/wrap-git-https.sh` wraps
`git-remote-http(s)`: those helpers are musl ELFs whose interpreter is
`/lib/ld-musl-armhf.so.1`, which is not on the Kindle. Without the wrap,
`git ls-remote https://…` exits 128.

```sh
export PATH=/mnt/us/bin:$PATH
git --version          # git version 2.47.3
```

HTTPS remotes use the CA file in the wrapper
(`GIT_SSL_CAINFO=/mnt/us/opt/git/ssl/cert.pem`). Kindle `wget` to the
Alpine CDN reset here; download APKs on the computer.

**Do not** extract Alpine onto `/mnt/us/alpine` or `mount --bind`.

## 6. Vim on FAT

Same shape as git. Alpine musl/armv7 **Vim 9.1.1105**, huge, no GUI.

```bash
just pack-vim
scp work/vim-kindlehf.tar.gz kindle:/mnt/us/
ssh kindle 'sh /mnt/us/path/to/install-vim.sh'
```

Busybox `vi` stays `/bin/vi`. Real vim is `/mnt/us/bin/vim`. Runtime is
`VIMRUNTIME=/mnt/us/opt/vim/share/vim/vim91`. Fine over SSH. kTerm
works; e-ink will fight large redraws.

## 7. camp / fest on busybox ash

`/bin/bash` on modern Kindles is often busybox. Official
`camp shell-init bash` needs real bash (`complete`, `[[`, arrays). Put
`scripts/ash-camp.sh` at `$HOME/.ash_camp` (`HOME` is `/mnt/us` when
dropbear is started with `-H /mnt/us`) and source it from `.profile`:

```sh
. /mnt/us/.ash_camp
export ENV=/mnt/us/.ash_camp
```

You get `camp go` / `fest go` changing directory in the current shell.
Tab completion and Charm TUIs stay on the computer.

`fest init` looks for templates in `$HOME/.obey/fest`. If that cache is
missing it auto-syncs from GitHub, which needs the git HTTPS wrap
above. Copying a cache onto the device lets `fest init` run offline.

Build the binaries with `scripts/build-go.sh`. A `camp version` print
from `/mnt/us/bin/camp` is enough to prove the pipe. Do not copy a
whole Mac campaign onto 1 GB of RAM.

## Commands

```bash
just                  # list
just pack-git         # work/git-kindlehf.tar.gz
just pack-vim         # work/vim-kindlehf.tar.gz
just check            # scripts executable, ignore rules present
```

## Troubleshooting

| What you see | What it is |
|--------------|------------|
| `;log mrpi` does nothing / “not installed” | Véra has no MRPI. Do not wait. |
| Install USBNet hangs | On-device `xz`/`tar` of the package. Push the extracted `usbnetlite/` tree instead. |
| Stuck on a USBNet / RNDIS page | You tapped **Toggle USBNet**. Power off. Use `start-ssh`. |
| `ssh: Connection refused` | Dropbear is not running. Reboot does not start it. |
| `REMOTE HOST IDENTIFICATION HAS CHANGED` | New host key. `ssh-keygen -R <ip>`. |
| `Connection closed` in KEX | Wedged dropbear. Kill it, run `start-ssh`. |
| KOReader book does nothing | Launcher without `/mnt/us/koreader/`. `;kpm install koreader` again. |
| Scriptlet missing from library | Search. Restart once. File in `documents/` with `# Name:`. |
| Alpine extract “can’t create symlink” | FAT. Flatten on the computer. |
| `git ls-remote https://…` exits 128 | `git-remote-https` still a musl ELF. Run `wrap-git-https.sh`. |

## Do not

- Official Settings → Update (Véra’s ceiling on this generation is 5.19.6).
- Factory reset (kills the hotfix).
- Put an install `.bin` on the Kindle storage root.
- Expect KUAL.
- `rm -rf` anything that might have `/mnt/us` or `/proc` bind-mounted.
- Extract Alpine onto `/mnt/us/alpine`.
- Run a 20+ MB TUI inside a scriptlet.
- Store jailbreak books in git.

See [SECURITY.md](SECURITY.md) for the publish checklist. This repo stays
private until that list is empty.

## License

MIT for the scripts in this tree. The tarballs `just pack-git` /
`just pack-vim` produce contain Alpine packages with their own licenses
(git is GPL-2.0). Those blobs are not committed here.
