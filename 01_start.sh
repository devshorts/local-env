export GOPATH=$HOME/go
GOROOT="/opt/homebrew"
alias go="$GOROOT/bin/go"

export LOCAL_USER_MODULE_PATH=$USER_MODULE_PATH
export COPPER_WINSTON_LOG_FORMAT=prettyPrint
#export GEM_HOME=/Users/anton.kropp/.gem
#export PATH="$GEM_HOME/bin:$PATH"
export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"
export PATH="/opt/homebrew/opt/ruby@3.1/bin:$PATH"
export PATH="/opt/homebrew/opt/libressl/bin:$PATH"
export PATH="/Users/anton.kropp/Library/Python/3.9/bin:$PATH"
export PATH="/Applications/IntelliJ IDEA.app/Contents/MacOS:$PATH"
export PATH="/opt/homebrew/opt/trash/bin:$PATH"
export PATH="$GOPATH/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.npm/bin:$PATH"
export PATH=$PATH:/Users/akropp/bin
export PATH="$HOME/.local/bin:$PATH"
export EDITOR=vim
export VISUAL=vim

export CLAUDE_CODE_MAX_OUTPUT_TOKENS=32000000
export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=true

# source ~/src/.pnpm.completion.zsh
# source ~/.zsh-pnpm-completions/zsh-pnpm-completions.plugin.zsh

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

fpath=(~/.zsh/completions $fpath)

prompt steeef

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# . $HOME/src/personal/jira-cli-tooling/jira.sh

# zsh plugins
#  git clone https://github.com/chrisands/zsh-yarn-completions.git ~/.zsh-yarn-completions
source ~/.zsh-yarn-completions/zsh-yarn-completions.plugin.zsh


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
detect-installed act "brew install act"
detect-installed rbenv "brew install rbenv"

detect-installed tfenv "brew install tfenv"

detect-installed fabric-ai "brew install fabric-ai"
detect-installed ollama "brew install ollama"

detect-installed luarocks "brew install luarocks"
detect-installed yarn "npm install --global yarn"
detect-installed go "brew install go"
detect-installed clj "brew install clojure/tools/clojure"
detect-installed jira "brew install go-jira"
detect-installed direnv "brew install direnv"
detect-installed trash "brew install trash"
detect-installed uv "brew install uv"
detect-installed podman "brew install podman"
detect-installed lefthook "brew install lefthook"
alias rm=trash

eval "$(rbenv init - --no-rehash bash)"

detect-installed claude "npm install -g @anthropic-ai/claude-code"
detect-installed typescript-language-server "npm install -g typescript-language-server"

detect-installed "mcp-language-server"  "go install github.com/isaacphi/mcp-language-server@latest"

eval "$(direnv hook zsh)"

eval "$(brew shellenv)"
fpath=($HOMEBREW_PREFIX/share/zsh/site-functions $fpath)

# fixes nvm crap
unset PREFIX

# load fuzzy finder
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

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
function rb-main() {
  curr=`git symbolic-ref --short HEAD`
  git checkout main
  git pull
  git checkout $curr
  git rebase main
}

# rebase with master but prefer the master branch for all conflicts
function rb-main-keep() {
  curr=`git symbolic-ref --short HEAD`
  git checkout main
  git pull
  git checkout $curr
  git rebase main -Xours
}

# rebase with master but prefer the local branch for all conflicts
function rb-master-discard() {
  curr=`git symbolic-ref --short HEAD`
  git checkout main
  git pull
  git checkout $curr
  git rebase main -Xtheirs
}

function docker-prune() {
  docker kill $(docker ps -q)
  docker images | grep none | awk '{print $3}' |xargs docker rmi -f
  yes | docker volume prune
}

function ssh-gmail-keys(){
  ssh-add ~/.ssh/id_rsa
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


# always make git track upstream
git config --global push.autoSetupRemote true

function fmt () {
	MESSAGE="${1:=fmt}"
	noglob git add --all .
	noglob git commit -am $MESSAGE --no-verify && noglob git push
}

function ff() {
  fmt $1 || git push
}

alias ei="idea -e"
alias fabric=fabric-ai

alias e="code"
function prp {
  git pull; git rebase; git push
}

function push_hard  {
  git push; prp
}

function com {
  git commit -am "$@"

  push_hard
}

function rcop {
  rubocop rubocop --restart-server
}

. $HOME/.zsh/plugins/bd/bd.zsh

git config --global alias.tpush 'push'
git config --global alias.smush 'rebase -i main'

function ai-diff {
  git diff -U0 | fabric --pattern create_git_diff_commit
}

alias aid=ai-diff

function aiq {
  Q="$1"
  json_string=$(jq -n --arg Q "$Q" '{"model": "llama3.2", "prompt": $Q, "stream": false}')

  curl -s http://localhost:11434/api/generate -d $json_string | jq -r .response
}

autoload -U colors && colors


function template-mcp {
  MCP_CWD=`pwd` envsubst < $LOCAL_USER_MODULE_PATH/mcp.template > .mcp.json
}

function claude-skills-copy {
  cp -rv $LOCAL_USER_MODULE_PATH/claude/skills/* ~/.claude/skills
}

function recurse-delete-folder {
  FOLDER=$1

  if [[ ! -n "$FOLDER" ]]; then
    echo "Provide a folder to recursively delete."

    return 1
  fi

  find . -name "$FOLDER" -type d -prune -exec trash -v {} +
}

function install-git-commits {
  ln -s $LOCAL_USER_MODULE_PATH/git_completion/lib/ lib

  cp $LOCAL_USER_MODULE_PATH/git_completion/prepare-commit-msg .

  chmod +x prepare-commit-msg
}

# git gone - removes branches that are are merged upstream
git config --global alias.gone "! git fetch -p && git for-each-ref --format '%(refname:short) %(upstream:track)' | awk '\$2 == \"[gone]\" {print \$1}' | xargs -r git branch -D"

# https://github.com/nvm-sh/nvm#zsh
# respect .nvmrc in files
# place this after nvm initialization!
autoload -U add-zsh-hook
load-nvmrc() {
  local node_version="$(nvm version)"
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$node_version" ]; then
      nvm use >/dev/null 2>&1
    fi
  elif [ "$node_version" != "$(nvm version default)" ]; then
    # echo "Reverting to nvm default version"
    nvm use default >/dev/null 2>&1
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc


if type complete &>/dev/null; then
  _npm_completion () {
    local words cword
    if type _get_comp_words_by_ref &>/dev/null; then
      _get_comp_words_by_ref -n = -n @ -n : -w words -i cword
    else
      cword="$COMP_CWORD"
      words=("${COMP_WORDS[@]}")
    fi

    local si="$IFS"
    if ! IFS=$'\n' COMPREPLY=($(COMP_CWORD="$cword" \
                           COMP_LINE="$COMP_LINE" \
                           COMP_POINT="$COMP_POINT" \
                           npm completion -- "${words[@]}" \
                           2>/dev/null)); then
      local ret=$?
      IFS="$si"
      return $ret
    fi
    IFS="$si"
    if type __ltrim_colon_completions &>/dev/null; then
      __ltrim_colon_completions "${words[cword]}"
    fi
  }
  complete -o default -F _npm_completion npm
elif type compdef &>/dev/null; then
  _npm_completion() {
    local si=$IFS
    compadd -- $(COMP_CWORD=$((CURRENT-1)) \
                 COMP_LINE=$BUFFER \
                 COMP_POINT=0 \
                 npm completion -- "${words[@]}" \
                 2>/dev/null)
    IFS=$si
  }
  compdef _npm_completion npm
elif type compctl &>/dev/null; then
  _npm_completion () {
    local cword line point words si
    read -Ac words
    read -cn cword
    let cword-=1
    read -l line
    read -ln point
    si="$IFS"
    if ! IFS=$'\n' reply=($(COMP_CWORD="$cword" \
                       COMP_LINE="$line" \
                       COMP_POINT="$point" \
                       npm completion -- "${words[@]}" \
                       2>/dev/null)); then

      local ret=$?
      IFS="$si"
      return $ret
    fi
    IFS="$si"
  }
  compctl -K _npm_completion npm
fi
###-end-npm-completion-###


alias claude-prompt='npx tsx ~/src/personal/local-env/claude/cli/src/cli.ts'