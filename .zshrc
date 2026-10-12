# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

ENABLE_CORRECTION="true"

COMPLETION_WAITING_DOTS="true"

DISABLE_UNTRACKED_FILES_DIRTY="true"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting sudo)

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

setopt no_share_history
unsetopt share_history

source $HOME/.bash_aliases
source $ZSH/oh-my-zsh.sh
source $HOME/.ola-zshrc

# Added by swiftly
[[ -f "$HOME/.local/share/swiftly/env.sh" ]] && . "$HOME/.local/share/swiftly/env.sh"
# Add scout-tools to PATH
[[ "$PATH" != *"$HOME/.local/bin"* ]] && export PATH="$PATH:$HOME/.local/bin" || true
# scout: shell integration (scout cd, completion)
command -v scout >/dev/null && eval "$(scout shell-init zsh)"
# Put ccache wrappers first, after swiftly prepends its clang
export PATH="/usr/lib/ccache:${PATH//\/usr\/lib\/ccache:/}"
