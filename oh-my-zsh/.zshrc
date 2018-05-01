#=======================================================================
#               STARTUP TIMES
#=======================================================================
# zmodload zsh/zprof
start_time="$(date +%s)"

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh
ZSH_THEME="spaceship"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
export UPDATE_ZSH_DAYS=5

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
HIST_STAMPS="dd/mm/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
export ZSH_CUSTOM=$HOME/Dotfiles/oh-my-zsh

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Add wisely, as too many plugins slow down shell startup.

# PLUGINS =======================================================================
plugins=(
        zsh-syntax-highlighting
        alias-tips
        last-working-dir
        zsh-nvm
        jira
        vi-mode
        git
        gitfast
        zsh-completions
        command-not-found
        colored-man-pages
        z
        common-aliases
        brew
        zsh-autosuggestions
        zsh-iterm-touchbar
        )

# web-search - great plugin, google from the command line although I never use

source $ZSH/oh-my-zsh.sh

if [ -f ~/.config/exercism/exercism_completion.zsh ]; then
  . ~/.config/exercism/exercism_completion.zsh
fi

# EMOJI-CLI
if [ -f $ZSH_CUSTOM/plugins/emoji-cli/emoji-cli.zsh ]; then
  source $ZSH_CUSTOM/plugins/emoji-cli/emoji-cli.zsh
fi


#ENHANCD ================================================================
if [ -f ~/enhancd/init.sh ]; then
  # TODO add a check to see if script exists if not install it
  # Maybe try using zplug again
  source ~/enhancd/init.sh
else
  git clone https://github.com/b4b4r07/enhancd ~/enhancd
  source ~/enhancd/init.sh
fi

#=======================================================================
#   LOCAL SCRIPTS
#=======================================================================
# source all zsh and sh files inside dotfile/runcom
for script ($DOTFILES/shell_scripts/*) source $script

##---------------------------------------------------------------------------//
# FZF
##---------------------------------------------------------------------------//
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=241'

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

# Set Spaceship ZSH as a prompt
autoload -U promptinit; promptinit
prompt spaceship
