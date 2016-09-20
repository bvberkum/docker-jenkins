#!/bin/sh

test -n "$scriptname" || scriptname=jenkins-jobs

. ./vars.sh "$@"

. ./util.sh

#cmd='jenkins-jobs update $JTB_HOME/jjb-install-local.yaml:$JTB_HOME/dist/base.yaml'
cmd="'jenkins-jobs $@'"
echo cmd=$cmd
docker exec -ti $cname \
    bash -c $cmd

