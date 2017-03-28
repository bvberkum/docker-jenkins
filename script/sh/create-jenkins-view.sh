#!/bin/sh

set -e

test -e "$1" || {
  echo "Expected XML file: '$1'"
  exit 1
}
test -n "$2" || set -- "$1" "$(basename "$1" .xml)"
test -z "$3" || {
  echo "Surplus arguments: '$3'"
  exit 1
}

test -n "$api_user" || exit 105
test -n "$api_secret" || exit 106
test -n "$JENKINS_URL" || exit 107


cp $1 config.xml


curl -fs -o /dev/null \
    --user $api_user:$api_secret \
  $JENKINS_URL/view/$2/config.xml && {


  echo "Updating view '$2' (from $1)"
  curl -fSs \
    -XPOST -o /dev/null \
    -H "Content-Type: text/xml" \
    --user $api_user:$api_secret \
    -d @config.xml \
    $JENKINS_URL/view/$2/config.xml || exit $?

} || {


  echo "Creating view '$2' (from $1)"
  curl -fSs \
    -XPOST -o /dev/null \
    --user $api_user:$api_secret \
    -d @config.xml \
    -H "Content-Type: text/xml" \
    $JENKINS_URL/createView?name=$2 || exit $?

}

rm config.xml

# Id: docker-jenkins/0.0.5-dev script/sh/create-jenkins-view.sh
