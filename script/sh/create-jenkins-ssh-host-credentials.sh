#!/bin/sh

set -e

test -n "$1" || set -- "jenkins"
test -n "$2" || set -- "$1" "$(hostname) Docker SSH Key"
test -n "$3" || set -- "$1" "$2" "$(hostname -s)-docker-${1}-ssh-key"
test -z "$4" || {
  echo "Surplus arguments: '$4'"
  exit 1
}

test -n "$api_user" || exit 95
test -n "$api_secret" || exit 96
test -n "$JENKINS_URL" || exit 97


curl -fsS -o /dev/null \
  --user $api_user:$api_secret \
  $JENKINS_URL/credentials/store/system/domain/_/credential/$3/ && {

  echo "Credentials $3 exists"

} || {

  curl -fSs \
    -XPOST -o /dev/null \
    --user $api_user:$api_secret \
    -F json='{
        "": "2",
        "credentials": {
          "scope": "GLOBAL",
          "username": "'"$1"'",
          "privateKeySource": {
            "value": "2",
            "stapler-class": "com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey$UsersPrivateKeySource"
          },
          "passphrase": "",
          "description": "'"$2"'",
          "id": "'"$3"'",
          "stapler-class": "com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey",
          "$class": "com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey"
        },
      }' \
    \
    $JENKINS_URL/credentials/store/system/domain/_/createCredentials \
      && echo "Credentials $3 created" \
      || {
        echo "Failed creating credentials '$3'"
        exit 1
      }
}

# Id: docker-jenkins/0.0.5-dev script/sh/create-jenkins-ssh-host-credentials.sh
