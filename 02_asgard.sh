function asgard(){
  verb=$1
  url="https://qa.asgard.curalate.com/us-east-1/$2"
  shift
  http ${VERB} --verify=no "$url" -b
}

function next-ami(){
  cluster=$1

  prepare-ami $cluster true | \
    jq ".environment.images | reverse | .[0]"
}

function prepare-ami(){
  cluster=$1

  includeEnv=$2

  asgard GET "deployment/prepare/${cluster}?deploymentTemplateName=CreateAndCleanUpPreviousAsg&includeEnvironment=${includeEnv}"
}

function get-next-ami(){
  cluster=$1

  next=`next-ami ${cluster} | jq ".id"`

  prepare-ami ${cluster} "false" | jq ".lcOptions.imageId |= ${next}"
}

function deploy(){
  cluster=$1

  PAYLOAD=`get-next-ami $cluster`

  echo $PAYLOAD | asgard POST "deployment/start/${cluster}"
}
