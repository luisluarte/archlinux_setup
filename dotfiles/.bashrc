#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls -alFht --group-directories-first --color=always'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# nvim stuff
alias v='nvim'
alias sv='sudo nvim'

# git repos
alias repos='cd ~/Documents/repos'

# zathura fzf
z () {
    command zathura "$@" & disown;
}
alias zf='z "$(fzf)"'

# set default editor
export EDITOR=nvim
export VISUAL=nvim

# add script folder to path
export PATH="$HOME/bin:$PATH"

. "$HOME/.local/bin/env"
