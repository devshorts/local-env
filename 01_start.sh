function install-icdiff(){
  hash icdiff 2>/dev/null || {
    log-info "Installing icdiff"
    pip install git+https://github.com/jeffkaufman/icdiff.git
  }
}

function docker-login() {
  . ~/.docker-login
}

function ssh-gmail-keys(){
  ssh-add ~/.ssh/id_rsa.gmail
}

function clean-containers(){
  docker ps -a | grep Exited | xargs docker rm
  docker volume rm $(docker volume ls -qf dangling=true)
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

if [[ -f /usr/local/share/chtf/chtf.sh ]]; then
    source "/usr/local/share/chtf/chtf.sh"
fi

alias stripe="cd ~/stripe"
alias paradox="cd ~/src/paradox"

autoload -U colors && colors
