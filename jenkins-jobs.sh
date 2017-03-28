#!/bin/sh

set -e

test -n "$scriptname" || scriptname=jenkins-jobs

. ./vars.sh "$@"

. ./util.sh

#cmd='jenkins-jobs update $JTB_SRC_DIR/jjb-install-local.yaml:$JTB_SRC_DIR/dist/base.yaml'
cmd="'jenkins-jobs $@'"
echo cmd=$cmd
docker exec -ti $cname \
    bash -c $cmd

