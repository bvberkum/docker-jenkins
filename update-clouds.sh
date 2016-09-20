#!/bin/sh
set -e

test -n "$1" || set -- "configure-docker-cloud.groovy"
script=$1
shift
test -e "$script" || script="script/$script"
test -e "$script" || script="$script.groovy"
test -e "$script" || {
  echo No such script $script
  exit 1
}

test -n "$env" || {
  echo "no env"
  exit 1
}
test -n "$tag" || {
  echo "no tag"
  exit 1
}
test -n "$api_user" || {
  echo "no api_user"
  exit 1
}

echo "Copying and running Groovy script ($script)"
docker cp   $script  $cname:/opt/dotmpe/docker-jenkins/

./jenkins-cli.sh  $env $tag  groovy \
    /opt/dotmpe/docker-jenkins/$(basename $script) "$@"

