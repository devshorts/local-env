export GOPATH=$HOME/go
export GOROOT="/Users/akropp/go/go1.21.0"
alias go="$GOROOT/bin/go"
export COPPER_WINSTON_LOG_FORMAT=prettyPrint
export GEM_HOME=/Users/akropp/.gem
export PATH="$GEM_HOME/bin:$PATH"
export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"
export PATH="/opt/homebrew/opt/ruby@3.1/bin:$PATH"
export PATH="/opt/homebrew/opt/openjdk@11/bin:$PATH"
export PATH="/opt/homebrew/opt/libressl/bin:$PATH"
export PATH="$GOROOT/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export EDITOR=nvim
export VISUAL=nvim

export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=true

prompt steeef

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

. $HOME/src/personal/jira-cli-tooling/jira.sh

# zsh plugins
. $HOME/.zsh/plugins/bd/bd.zsh
. $HOME/.zsh/plugins/yarn-autocompletions/yarn-autocompletions.plugin.zsh

function install-git-diff(){
  hash delta 2>/dev/null || {
    log-info "Installing git delta"
    brew install git-delta
  }
}

export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # Th\is loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

detect-installed nvm "brew install nvm"

detect-installed tfenv "brew install tfenv"

detect-installed fig "brew install --cask fig"

detect-installed go "brew install go"

# fixes nvm crap
unset PREFIX

# load fuzzy finder
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

function nb {
  # git checkout -b $USER/$1
  new-branch "$"
}

function fetchnotes()  {
   set -x
   git fetch && git fetch origin refs/notes/commits:refs/notes/origin/commits && git notes merge -v origin/commits
   set +x
}

function all {
  set -x
  if [[ ! $1 ]]; then
    echo "Missing commit message"
  else
    git add --all .
    git commit -am "$1"
  fi
  set +x
}

function master {
  git checkout master
  git pull
}

function main {
  git checkout main
  git pull
}

function docker-login() {
  . ~/.docker-login
}

# rebase master
function rb-master() {
  curr=`git symbolic-ref --short HEAD`
  git checkout master
  git pull
  git checkout $curr
  git rebase master
}

# rebase with master but prefer the master branch for all conflicts
function rb-master-keep() {
  curr=`git symbolic-ref --short HEAD`
  git checkout master
  git pull
  git checkout $curr
  git rebase master -Xours
}

# rebase with master but prefer the local branch for all conflicts
function rb-master-discard() {
  curr=`git symbolic-ref --short HEAD`
  git checkout master
  git pull
  git checkout $curr
  git rebase master -Xtheirs
}

function docker-prune() {
  docker kill $(docker ps -q)
  docker images | grep none | awk '{print $3}' |xargs docker rmi -f
  yes | docker volume prune
}

function ssh-gmail-keys(){
  ssh-add ~/.ssh/id_rsa.gmail
}

function clean-containers(){
  docker ps -a | grep Exited | xargs docker rm
  docker volume rm $(docker volume ls -qf dangling=true)
}

function trace() {
  strace -p $1 -f -s 1000 -e trace=network 2>&1
}

function gclone(){
  git clone $@
}

function encrypt() {
  openssl enc -aes-256-cbc -e -in $1 -out encrypted-$1
}

function decrypt() {
  openssl enc -aes-256-cbc -d -in $1 -out decrypted-$1
}

function smushfix() {
  git add --all . && git commit -am "fix" && git smush
}

function ssh-proxy() {
  HOST=$1
  PORT=$2
  ssh -L $PORT\:localhost:$PORT $HOST
}

function emacsd() {
  PROCESS=Emacs
  number=$(ps aux | grep $PROCESS | wc -l)

  if [ $number -eq 1 ]; then
    echo "Starting emacs daemon"
    /Applications/Emacs.app/Contents/MacOS/Emacs --daemon > /dev/null 2>&1
  fi
}

if [[ -f /usr/local/share/chtf/chtf.sh ]]; then
    source "/usr/local/share/chtf/chtf.sh"
fi
#emacsd

install-git-diff

alias emacs=emacsclient
alias emacs_gui="emacsclient --create-frame"
alias gi=git
alias paradox="cd ~/src/paradox"
alias vsc="/Applications/Visual\ Studio\ Code.app/Contents/MacOS/Electron"

function ff() {
  fmt $1 || git push
}

alias gg="git push"

. $HOME/.zsh/plugins/bd/bd.zsh

git config --global alias.tpush 'push'
git config --global alias.smush 'rebase -i master'

autoload -U colors && colors

# https://docs.github.com/en/github/authenticating-to-github/managing-commit-signature-verification/telling-git-about-your-signing-key
# if [ -r ~/.zshrc ]; then echo 'export GPG_TTY=$(tty)' >> ~/.zshrc; \
#   else echo 'export GPG_TTY=$(tty)' >> ~/.zprofile; fi
