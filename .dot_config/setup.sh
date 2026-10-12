#!/usr/bin/env bash

# Install apt stuff
sudo apt update && sudo apt install zsh fontconfig curl

# Install zsh stuff
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
chsh -s "$(which zsh)"
ZSH_CUSTOM=~/.oh-my-zsh/custom
git clone -q https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
git clone -q https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
git clone -q --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"

# Clone dotfile repo
git clone --bare git@github.com:ovaag/dotfiles.git $HOME/.dotfiles

dots () {
  git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" "$@"
}

dots checkout --force
dots config --local status.showUntrackedFiles no
# A bare clone has no fetch refspec, so add one to get origin/base for status.
dots config --local remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
dots fetch
dots branch -u origin/base


# Install fonts
fc-cache -f -v

# Tilix settings. Update the file with:
#   dconf dump /com/gexperts/Tilix/ > ~/.dot_config/tilix.dconf
if command -v tilix >/dev/null; then
  dconf load /com/gexperts/Tilix/ < "$HOME/.dot_config/tilix.dconf"
fi

