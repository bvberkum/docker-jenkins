#!/bin/sh

test -n "$scriptname" || scriptname=jenkins-cli

jenkins_cli()
{
  echo "[$cname] Jenkins-CLI $* shift"

  local c=0
  . ./vars.sh "$@"
  # XXX: not needed (Linux)
  #case "$(uname)" in
  #  Darwin )
  #      shift 2
  #    ;;
  #esac
  #echo "[$cname] Jenkins-CLI $* shift $c"
  #test $c -eq 0 || shift $c
  
  echo "[$cname] Jenkins-CLI $*"
  docker exec -ti $cname \
    /usr/local/bin/jenkins-cli "$@" || exit $?
}

jenkins_cli "$@"

