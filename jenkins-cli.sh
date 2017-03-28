#1/bin/sh

. std.lib.sh
test -n "$1" || error "hostname argument expected" 1
url=$1
test -e jenkins-cli.jar || {
  test -z "$2" || error "surplus arguments '$2'" 1
  wget http://$1/jnlpJars/jenkins-cli.jar
  exit 1
}

shift

test -e .ssh_id_rsa && {
  pk=.ssh_id_rsa
} || {
  pk=$(echo $HOME/.ssh/id_?sa | cut -f 1 -d " ")
}

test -n "$pk" -a -e "$pk" || {

  echo "No keyfile for CLI: $pk"; exit 1;
}

jar_f="-s http://$url -i $pk"
java -jar ./jenkins-cli.jar $jar_f "$@" \
  || exit $?

