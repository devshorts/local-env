export SCALA_HOME=/usr/local/share/scala-2.10
export CURALATE_HOME=/Users/antonkropp/src/curalate
export PATH=$PATH:$SCALA_HOME/bin

function install-icdiff(){
  hash icdiff 2>/dev/null || {
    log-info "Installing icdiff"
    pip install git+https://github.com/jeffkaufman/icdiff.git
  }
}

function local-java-env-vars(){
  export JAVA_HOME=`/usr/libexec/java_home -v '1.8'`
  export MAVEN_OPTS="-Xmx1024M -Xms1024M -Djava.awt.headless=true"
}

function docker-login() {
  ~/.docker-login
}

function start-docker(){
  cmd="docker-machine env default"

  eval ${cmd} > /dev/null

  if [ "$?" != "0" ]; then
    log-warn "Docker machine not running, starting.."

    docker-machine start
  fi

  eval $(docker-machine env)
}

function start-containers(){
  docker start francois
  docker start mining-db
  docker start curalate-web
}

function list-lambdas(){
  AWS_DEFAULT_PROFILE=$1

  if [ "$AWS_DEFAULT_PROFILE" == "" ]; then
    AWS_DEFAULT_PROFILE=qa
  fi

  aws lambda list-functions --profile ${AWS_DEFAULT_PROFILE} | jq '.Functions[].FunctionName'
}

function import-mysql(){
  docker exec -it curalate-web sh -c "mysql -u root -p < /dumps/${1}"
}

function ssh-gmail-keys(){
  ssh-add ~/.ssh/id_rsa.gmail
}

function ssh-aws() {
  host=$1
  ssh -i ~/.aws/curalate-qa-developers.pem ubuntu@$host
}

function report() {
  mvn clean test -P integration scoverage:report; mvn generate-sources scoverage:report-only; o target/site/scoverage/index.html
}

function ssh-aws-prod() {
  host=$1
  ssh -i ~/.aws/storably-prod.pem ubuntu@$host
}

function ssh-jenkins {
  host=$1
  ssh -i ~/.aws/jenkins-slave.pem ubuntu@$host
}

function load-antigen(){
  source $USER_MODULE_PATH/scripts/antigen.zsh

  antigen-bundle Tarrasch/zsh-bd
}

function new-service(){
  mvn archetype:generate \
  -DarchetypeGroupId=com.curalate \
  -DarchetypeArtifactId=sample-service-archetype
}

function new-lib(){
  mvn archetype:generate \
  -DarchetypeGroupId=com.curalate \
  -DarchetypeArtifactId=vanilla-archetype-archetype
}

function restart-docker-machine(){
  docker-machine stop;
  docker-machine start;
}

function gh(){
  branch=$1

  if [ "$branch" == "" ]; then
    branch="origin"
  fi

  URL=`git config --get remote.${branch}.url | sed 's/git@//' | sed 's/:/\//'`

  open "http://$URL"
}

function start-pinsights(){
  ~/src/curalate/pinsights/pinsights-web/pinsights-web-admin/debug
}

function clean-containers(){
  docker ps -a | grep Exited | xargs docker rm
  docker volume rm $(docker volume ls -qf dangling=true)
}

function copy-prod {
  set -x
  FILE=$1
  HOST=$2
  FILE_NAME=`basename $FILE`
  scp -i ~/.aws/storably-prod.pem $FILE ubuntu@$HOST:/home/ubuntu/$FILE_NAME
}

function curalate-web() {
  docker run -d \
  -p 3307:3306 \
  -v ~/dumps:/dumps \
  --name curalate-web \
  -e MYSQL_ALLOW_EMPTY_PASSWORD=true \
  mysql:5.6
}

function list-jenkins(){
  aws ec2 describe-instances \
  --filters 'Name=tag:Application,Values=Jenkins' \
  --profile prod \
  --region us-east-1 | \
  jq .
}

function list-jenkins-ips() {
  list-jenkins | jq ".Reservations[] .Instances[] | .NetworkInterfaces[] | .PrivateIpAddresses"
}

function francois(){
  docker run -d -p 9090:9090 \
    -e JENKINS_URL="https://jenkins.curalate.com" \
    -e JENKINS_USER=devshorts \
    -e JENKINS_TOKEN=$JENKINS_TOKEN \
    --name francois \
    paradoxical/francois
}

function load-aws-autocomplete(){
  complete -C aws_completer aws
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

function watch-jenkins() {
  unwatch-jenkins

  jenkinsgrowler -s https://jenkins.curalate.com/ -j \
    "curalate-social-mining-service/job/master,
    Curalate-Twitters/job/master,
    twitter-miners/job/v3%2Fmaster,
    Curalate-Logging/job/master,
    Curalate-AWS/job/master,
    Curalate-Global/job/master,
    Curalate-Utils/job/master,
    Curalate-Ops-Service/job/master,
    curalate-semantic-tagging/job/master
    " \e .
    -u devshorts -p $JENKINS_TOKEN &
}

function jenkins {
  RAW_BRANCH=`git symbolic-ref --short HEAD`
  BRANCH=`perl -MURI::Escape -e "print uri_escape(\"$RAW_BRANCH\");"`
  JOB=`basename \`pwd\``
  o https://jenkins.curalate.com/job/curalate-$JOB/job/$BRANCH/
}

function unwatch-jenkins() {
  pkill -f jenkinsgrowler
}

function v {
  curacmds github::versions -r curalate/${1} | head -n 1
}
load-aws-autocomplete

function uss {
 curl https://search-curalate-universal-search-qernyw2s6y2xeymhljm6c4as3q.us-east-1.es.amazonaws.com/current_index/item/_search?q=cuid:$1 | jq .
}
function ussqa {
 curl https://search-curalate-dev-bixcyg2pyu73cigfjivxij7xgm.us-east-1.es.amazonaws.com/current_index/item/_search?q=cuid:$1 | jq .
}

function docker-run-all {
  docker ps -a --format '{{.ID}}' | xargs docker $1
}

function j9 (){
  export JAVA_HOME=`/usr/libexec/java_home -v 9`
}

function j8(){
  export JAVA_HOME=`/usr/libexec/java_home -v 1.8`
}

if [[ -f /usr/local/share/chtf/chtf.sh ]]; then
    source "/usr/local/share/chtf/chtf.sh"
fi

alias parquet-tools="java -jar ~/tools/parquet-tools-1.9.1-SNAPSHOT.jar"
alias mvb="mvn compile -T 1C"
alias curalate="cd ~/src/curalate"
alias paradox="cd ~/src/paradox"
alias subl="open -a /Applications/Sublime\ Text.app"
alias mining="cd ~/src/curalate/mining/curalate-mining"
alias miners="cd ~/src/curalate/mining/curalate-social-miners"
alias sbt="sbt -Dscala.color=true -mem 2048"
alias cr="curacmd run"
alias jdgui="java -jar ~/tools/jd-gui-1.4.0.jar"
alias scala211="/usr/local/share/scala-2.11.8/bin/scala -Dscala.color"

nvm use 6

install-icdiff
load-antigen

local-java-env-vars

source /usr/local/Cellar/awscli/1.10.16/libexec/bin/aws_zsh_completer.sh

## set the prompt

autoload -U colors && colors

local parse_special='%{$fg[yellow]%}$CURALATE_ENV%{$reset_color%}'

export RPROMPT="${parse_special}"
