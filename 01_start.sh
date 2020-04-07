export GOPATH=$HOME/go
export PATH=$PATH:/$GOPATH/bin

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh


function install-icdiff(){
  hash icdiff 2>/dev/null || {
    log-info "Installing icdiff"
    pip install git+https://github.com/jeffkaufman/icdiff.git
  }
}

function nb {
  git checkout -b $USER/$1
}

function docker-login() {
  . ~/.docker-login
}

function rb-master() {
  curr=`git symbolic-ref --short HEAD`
  git checkout master
  git pull
  git checkout $curr
  git rebase master
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

alias emacs=emacsclient
alias emacs_gui="emacsclient --create-frame"
alias gi=git
alias paradox="cd ~/src/paradox"
alias vsc="/Applications/Visual\ Studio\ Code.app/Contents/MacOS/Electron"
. $HOME/.zsh/plugins/bd/bd.zsh

git config --global alias.tpush 'push'
git config --global alias.smush 'rebase -i master'

autoload -U colors && colors
