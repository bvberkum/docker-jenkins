#!/bin/sh

# Id: docker-jenkins/0.0.2 util.sh

version=0.0.2 # docker-jenkins

set -e

test -n "$scriptdir" || scriptdir="$(dirname "$0")"

. $scriptdir/table.lib.sh
. $scriptdir/os.lib.sh


# stdio/stderr/exit util
log()
{
	[ -n "$(echo "$*")" ] || return 1;
	echo "[$hostname:$scriptname.sh:$cmd] $1"
}
err()
{
	[ -n "$(echo "$*")" ] || return 1;
	echo "Error: $1 [$hostname:$scriptname.sh:$cmd]" 1>&2
	[ -n "$2" ] && exit $2
}

incr_c()
{
  c=$(( $c + 1 ))
}

trueish()
{
  test -n "$1" || return 1
  case "$1" in
    on|true|y*|j*|1)
      return 0;;
    * )
      return 1;;
  esac
}

noop()
{
  printf ""
}

fnmatch()
{
  case "$2" in $1 ) return 0 ;; *) return 1 ;; esac
}

docker_exec_jenkins_cli()
{
  docker exec -ti $cname \
            /usr/local/bin/jenkins-cli "$@" || exit $?
}

