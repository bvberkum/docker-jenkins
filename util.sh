#!/bin/sh

# Id: docker-jenkins-mpe/0.0.1 util.sh

version=0.0.1 # docker-jenkins-mpe

# stdio/stderr/exit util
log()
{
	[ -n "$(echo "$*")" ] || return 1;
	echo "[$scriptname.sh:$cmd] $1"
}
err()
{
	[ -n "$(echo "$*")" ] || return 1;
	echo "Error: $1 [$scriptname.sh:$cmd]" 1>&2
	[ -n "$2" ] && exit $2
}

