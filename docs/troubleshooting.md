# Kindle troubleshooting

USBNet page, SSH connection refused, git on FAT, KUAL vs KPM. Longer
answers are in the [FAQ](faq.md).

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

Back to the [guide](guide.md).
