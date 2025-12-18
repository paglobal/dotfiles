# My dotfiles

## Setup

- Install arch btw
- Run `sudo pacman -S chezmoi`
- Run `chezmoi init --apply paglobal`
- Run `~/scripts/install-yay.sh`
- Update `~/pkglist.txt` according to your needs and preferences
- Run `~/scripts/install-from-pkglist.sh`
- Edit `~/scripts/idempotent-setup.sh` with your details if
you're setting up on a machine that doesn't belong to `paglobal`
- Run `~/scripts/idempotent-setup.sh`
- Learn [chezmoi](https://www.chezmoi.io/) to adequately manage
your dotfiles as you please (you might want to re-add the
`~/scripts/idempotent-setup.sh` and `~/pkglist.txt` files)
- Do with your system and the dotfiles as you please, just don't
try to push your changes back here if you're not `paglobal`
