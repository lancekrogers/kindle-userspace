# What this repo is allowed to contain

This tree is the version that can go public. Lab notes, device dumps, and
jailbreak payloads stay out of it.

## Never commit

- Device serials, Wi-Fi MACs, lab IPs, host aliases
- SSH private keys, `authorized_keys`, dropbear host keys
- Jailbreak books (`*.azw3`, hotfix payloads, unpacked Véra trees)
- Firmware images, `update_kindle_*.bin`, rootfs extracts, UKS PEMs
- DRM strippers, DeDRM plugins, Kindle store book files
- Unsigned `.bin` update packages (USBNetLite, MRPI, etc.)
- Calibre debug dumps that list personal documents

## Do not merge from the private explore workitem

The campaign lab notebook is a different tree. Do not copy it here. If a
script from the lab is useful, rewrite it so it has no host paths, no
serials, and no payloads, then add that rewrite.

## Flip to public

1. `gh repo view --json isPrivate` still says true until you flip it.
2. `git grep -E 'G0[0-9]|BEGIN (OPENSSH|RSA)|authorized_keys|1949:|/etc/uks'`
   and read the hits. Serials and keys are the usual leaks.
3. Confirm `work/`, `*.tar.gz`, `*.apk`, `*.bin`, `*.pem` are gitignored and
   untracked.
4. README still says this is L1 userspace, not a jailbreak kit.
5. Then `gh repo edit --visibility public`.

## Scope

Right to repair on hardware you own. Amazon still boots the device. We do
not attack Amazon infrastructure and we do not strip store DRM.
