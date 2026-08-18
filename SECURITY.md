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
- Prebuilt `camp` / `fest` binaries (build them with `just pack-fest`)

## Pull requests

Do not send device serials, keys, jailbreak books, firmware dumps, or
lab IPs. If a script from a private notebook is useful, rewrite it so it
has no host paths and no payloads.

## Scope

Right to repair on hardware you own. Amazon still boots the device. We do
not attack Amazon infrastructure and we do not strip store DRM.
