# My dotfiles

## Setup

- Install arch btw (desktop type installation with niri is
recommended)
- Log in as your preferred user
- Run `sudo pacman -S chezmoi`
- Run `chezmoi init --apply paglobal`
- Run `~/.local/bin/install-yay.sh`
- Update `~/assets/txts/pkglist.txt` according to your needs and preferences (note
that certain packages may have certain pre-requisites, like `steam`
requiring you to enable `multilib`)
- Run `~/.local/bin/install-from-pkglist.sh`
- Edit `~/.local/bin/idempotent-setup.sh` with your details if
you're setting up on a machine that doesn't belong to `paglobal`
- Run `~/.local/bin/idempotent-setup.sh`
- Run `~/.local/bin/add-lid-conf.sh` if you wish to add the lid configuration (you
can edit the script first)
- Reboot your system to make sure all your changes are adequately reflected
- Learn [chezmoi](https://www.chezmoi.io/) to adequately manage
your dotfiles as you please (you might want to re-add the
`~/.local/bin/idempotent-setup.sh` and `~/assets/txts/pkglist.txt` files)
- Do with your system and the dotfiles as you please, just don't
try to push your changes back here if you're not `paglobal`
