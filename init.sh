#!/usr/bin/env bash

# Id: docker-jenkins-mpe/0.0.1 init.sh

. $(dirname $0)/util.sh
scriptname=/opt/dotmpe/docker-jenkins/init

SRC_PREFIX=/src/

install_jjb()
{
  log "Cloning JJB.."
  mkdir -vp $SRC_PREFIX
  git clone https://git.openstack.org/openstack-infra/jenkins-job-builder $SRC_PREFIX/build/jjb \
    || err "Error cloning to $SRC_PREFIX/build/jjb" 1

  log "Installing JJB.."
  pushd $SRC_PREFIX/build/jjb
  #sudo python setup.py install
  python setup.py install \
    && log "JJB install complete" \
    || err "Error during JJB installation" 1
  popd

  # XXX --user
  #export PATH=$PATH:/var/jenkins_home/.local/bin

  jenkins-jobs --version && {
    log "JJB install OK"
  } || {
    err "JJB installation invalid" 1
  }
}

init_jjb()
{
  cat <<HERE

[job_builder]
allow_empty_variables=True
ignore_cache=True
keep_descriptions=True
include_path=.:config/build
recursive=False
allow_duplicates=False
exclude=.travis.*:build:manual:vendors

[jenkins]
user=admin
password=$2
url=http://$1/
query_plugins_info=False

HERE
}

init_cli()
{
  cat <<HERE
#!/bin/sh
cd $$JENKINS_HOME/
java -jar war/WEB-INF/jenkins-cli.jar -s http://$1/ \$@
HERE
}

test -n "$1" && type $1 &> /dev/null && {
  cmd=$1
  shift 1
  $cmd $@
}

