#!/bin/sh

set -e


update_node()
{
  test -n "$1" || err "expected node XML config path name" 1
  test -e "$1" || err "no such node XML config path: '$1'" 1
  path=$1 ; shift 1
  name=$1 ; shift 1
  test -n "$name" || name=$(basename $1 .xml)
  # XXX: Params are not used atm.
  #test -z" $params" || eval $params

  docker cp $1 $cname:/tmp || { err "copy failed"; return 1; }
  docker exec /opt/dotmpe/docker-jenkins/init.sh init_node \
        /tmp/$(basename $1) $name || return
  #|| return $?
}

generate_node()
{
  local name=$1 file="/tmp/jenkins-nodes/$1.xml"
  shift

  docker exec $cname /opt/dotmpe/docker-jenkins/init.sh \
    generate_node "$name" "$file" "$@" \
      || continue
  docker exec $cname /opt/dotmpe/docker-jenkins/init.sh \
    init_node "$file" "$name" \
      || continue
  docker exec $cname rm -rf $file \
    || continue
}

update_nodes_from_table()
{
  test -n "$1" || err "triggers tab file expected" 1
  test -z "$2" || err "surplus args: '$2'" 1

  local \
    path_offset=$(fixed_table_hd_offsets $1 PATH PATH ) \
    name_offset=$(fixed_table_hd_offsets $1 PATH NAME ) \
    params_offset=$(fixed_table_hd_offsets $1 PATH PARAMS ) \
    path_var= name_var= param_vars=

  read_nix_style_file $1 | while read line
  do

    path_var="$(echo $(echo "$line" | cut -c1-$name_offset ))"
    test "$path_var" != "-" || path_var=
    name_var="$(echo $(echo "$line" | cut -c$(( $name_offset + 1))-$params_offset ))"
    param_vars="$(echo $(echo "$line" | cut -c$(( $params_offset + 1 ))- ))"

    test -n "$path_var" -a -e "$path_var" && {
      update_node "$path_var" "$name_var" "$param_vars" \
        || continue
    } || {
      path_var=/tmp/$name_var.xml
      generate_node "$name_var" "$path_var" "$param_vars"
    }

  done
}

