#=======================================================================
#               STARTUP TIMES
#=======================================================================
# zmodload zsh/zprof
start_time="$(date +%s)"
#---------------------------------------------------------------------------//
# ZPLUG
#---------------------------------------------------------------------------//
if [[ ! -d ~/.zplug ]]; then
  git clone https://github.com/zplug/zplug ~/.zplug
  source ~/.zplug/init.zsh && zplug update --self
fi

# Essential
source ~/.zplug/init.zsh

# Make sure to use double quotes
zplug "zsh-users/zsh-history-substring-search"
zplug "zsh-users/zsh-autosuggestions"
zplug "lukechilds/zsh-nvm"
zplug "zsh-users/zsh-completions"
zplug "plugins/git",   from:oh-my-zsh
zplug "plugins/git-fast",   from:oh-my-zsh
zplug "djui/alias-tips"
zplug "plugins/zsh-iterm-touchbar",   from:oh-my-zsh
zplug "plugins/brew",   from:oh-my-zsh
zplug "plugins/last-working-dir", from:oh-my-zsh
zplug "plugins/common-aliases", from:oh-my-zsh
zplug "plugins/brew", from:oh-my-zsh
zplug "plugins/jira", from:oh-my-zsh
zplug "plugins/vi-mode", from:oh-my-zsh
zplug "plugins/vi-mode", from:oh-my-zsh
zplug "b4b4r07/enhancd", use:init.sh
zplug "b4b4r07/emoji-cli"
zplug "denysdovhan/spaceship-prompt", use:spaceship.zsh, from:github, as:theme

# Set the priority when loading
# e.g., zsh-syntax-highlighting must be loaded
# after executing compinit command and sourcing other plugins
# (If the defer tag is given 2 or above, run after compinit command)
zplug "zsh-users/zsh-syntax-highlighting", defer:2
zplug 'zplug/zplug', hook-build:'zplug --self-manage'

# Install plugins if there are plugins that have not been installed
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

# Then, source plugins and add commands to $PATH
zplug load

#=======================================================================
#   LOCAL SCRIPTS - Including Environment Variables
#=======================================================================
for script ($DOTFILES/shell_scripts/*) source $script

##---------------------------------------------------------------------------//
# FZF
##---------------------------------------------------------------------------//
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# STARTUP TIMES (CONTD)================================================
end_time="$(date +%s)"
# Compares start time defined above with end time above and prints the
# difference
echo load time: $((end_time - start_time)) seconds

##---------------------------------------------------------------------------//
# LOL
##---------------------------------------------------------------------------//
# if brew ls --versions fortune > /dev/null;then
#   runonce <(fortune | cowsay | lolcat)
# fi
# zprof
archey -o
