#!/bin/sh

set -e


tmpf=/tmp/$(uuidgen)
env > $tmpf


scriptname=show-vars
test -n "$tag" || . ./vars.sh "$@"
test -n "$api_user" || get_env

type err >/dev/null 2>&1 || { . ./util.sh; }



show_new_env()
{
  while read decl
  do
    varname="$(echo "$decl" | sed 's/^\([^=]*\)=.*$/\1/')"
    #echo "decl='$decl'"
    grep -qs '^'"$varname" "$1" && continue
    #echo "varname='$varname'"
    grep -qs '^'$varname $1 || {
        echo "$varname"
        #echo "$varname: $(eval echo \"\$$varname\")"
    }
  done
}

get_vars()
{
  grep -E '^[A-Za-z0-9_]+=.*' | sed 's/^\([^=]*\)=.*$/\1/'
}



echo
log "New Local Env: "
set  |  get_vars  |  show_new_env $tmpf | column

echo
log "New Global Env: "
env  |  get_vars  |  show_new_env $tmpf | column


