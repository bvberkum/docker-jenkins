#!/bin/sh

test -n "$scriptname" || scriptname=jenkins-cli

. ./vars.sh "$@"
case "$(uname)" in
  Darwin )
      shift 2
    ;;
esac

echo "[$cname] Jenkins-CLI $@"
docker exec -ti $cname \
  /usr/local/bin/jenkins-cli "$@" || exit $?

