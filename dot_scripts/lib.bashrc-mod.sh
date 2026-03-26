# yazi function
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd <"$tmp"
  [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

# sudeedit alias
alias se="sudoedit"

# neovim alias
alias vi="nvim"

# change default editor from nano to vim
export EDITOR="nvim"

# pnpm alias
alias pn=pnpm

# python alias
alias python="python3"

# prompt config
source lib.git-prompt.sh
PS1='\[\e[1;34m\]\u@\h\[\e[0m\] \w$(__git_ps1 " \[\e[1;32m\]%s\[\e[0m\]"): \$ '

# remove packages with yay (stolen from reddit)
alias yeet="yay -Rns"

# initialize zoxide
eval "$(zoxide init bash)"

# noctalia shell ipc alias
alias nsi="qs -c noctalia-shell ipc call"
