# FAQ

Short answers for the searches that land here. The long pipe is in the
[guide](guide.md).

## How do I SSH into a jailbroken Kindle Scribe?

Do not tap **Toggle USBNet**. That enables the USB ethernet gadget and
traps the UI on a page you leave by powering off.

Install [USBNetLite](https://github.com/notmarek/kindle-usbnetlite) (khf
build on firmware ≥ 5.18), copy [`scripts/start-ssh.sh`](../scripts/start-ssh.sh)
to `/mnt/us/bin/start-ssh` and `documents/Start-SSH.sh`, then after every
reboot:

```sh
/mnt/us/bin/start-ssh
```

That starts dropbear on **Wi-Fi** (`wlan0`, port 22). From the computer:
`ssh root@YOUR_KINDLE_IP`. See the [guide](guide.md#4-wi-fi-ssh-do-not-tap-toggle-usbnet).

## Does this work on Kindle firmware 5.19.5?

Yes. It was written on a first-gen Kindle Scribe on **5.19.5**, hard-float
**kindlehf** (any Kindle on ≥ 5.16.3). You still need a jailbreak first.
On 5.17.1–5.19.6 that is currently **Véra**. This repo does not ship it.

## Why is KUAL gone? What is KPM?

KUAL is dead on firmware **≥ 5.19.4**. Use **KPM** (`;kpm update`,
`;kpm install koreader`). Véra does not ship MRPI. `;log mrpi` printing
`mrpi is not installed` is normal.

## Can I install git on a Kindle?

Yes, if you flatten it first. `/mnt/us` is **FAT**: no symlinks, no
Alpine chroot. `just pack-git` builds musl/armv7 **git 2.47.3** as regular
files. `just pack-vim` does the same for Vim 9.1.

Do not extract Alpine onto `/mnt/us/alpine`. Do not `mount --bind` and
`rm -rf`. That deletes the library.

## I am stuck on the USBNet / RNDIS page.

You tapped Toggle USBNet, or you plugged USB with the gadget on. Power
the Kindle off. Next time use `start-ssh` on Wi-Fi only.

## `ssh: Connection refused`

Dropbear is not running. A reboot does not start it. Run `/mnt/us/bin/start-ssh`
on the device, then try again.

## `git ls-remote https://…` exits 128

`git-remote-https` is a musl ELF whose interpreter is
`/lib/ld-musl-armhf.so.1`, which is not on the Kindle. Run
[`scripts/wrap-git-https.sh`](../scripts/wrap-git-https.sh) after install.

## Can I run Festival / fest on a Kindle?

Optional. [Fest](https://github.com/Obedience-Corp/fest) is a separate
public CLI. `just pack-fest` cross-compiles it. Wizards stay on the
computer. Details: [fest.md](fest.md).

## Is this a Kindle jailbreak?

No. No Véra books, no hotfix, no firmware dump, no DRM tools. Bring your
own jailbreak, then use this as the userspace.
