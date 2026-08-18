# Kindle Scribe userspace guide

Amazon still boots the Kindle. After a public jailbreak you can still run
your own programs on the userstore. SSH over Wi-Fi, git and vim on FAT
`/mnt/us`, no Toggle USBNet.

This is the full pipe. The [README](../README.md) is the landing page.

Tested on a first-gen Kindle Scribe, firmware **5.19.5**, hard-float
**kindlehf** (firmware ≥ 5.16.3). Kernel 4.9, glibc 2.35, `armv7l`.

## What you need

- A Kindle you already jailbroke. On 5.17.1–5.19.6 that is currently
  **Véra** (Ava / sparklerfish, August 2026). This repo does not unpack
  those books.
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

## 7. Festival (optional)

[Fest](https://github.com/Obedience-Corp/fest) is a separate public CLI.
Do not vendor it into this tree. Build and install: [fest.md](fest.md).

```bash
just pack-fest
```

Ash hooks live in `scripts/ash-camp.sh`. Official `camp shell-init bash`
needs real bash; `/bin/bash` on the Kindle is busybox.

## Commands

```bash
just                  # list
just pack-git         # work/git-kindlehf.tar.gz
just pack-vim         # work/vim-kindlehf.tar.gz
just pack-fest        # work/fest-kindlehf.tar.gz (optional)
just check            # scripts executable, ignore rules present
```

When something breaks, see [troubleshooting](troubleshooting.md).
When you are ready to open the repo, see [SECURITY.md](../SECURITY.md).
