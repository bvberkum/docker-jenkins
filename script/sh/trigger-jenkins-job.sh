#!/bin/sh

set -e


test -n "$api_user" || exit 101
test -n "$api_secret" || exit 102
test -n "$JENKINS_URL" || exit 103


trigger_build()
{
  local path=job/$(echo "$1" | sed 's/\//\/job\//g' ) \
    post_f=" "

  shift

  test -n "$1" && {

    while test -n "$1"
    do
      post_f=" $post_f -d $1"
      shift
    done


    curl -fSs -XPOST $post_f -o /dev/null \
      --user $api_user:$api_secret \
      $JENKINS_URL/$path/buildWithParameters \
        && echo "Triggered parameterized build at $path ($post_f)" \
        || echo "Error triggering parameterized build at $path ($post_f)"


  } || {

    curl -fSs -XPOST $post_f -o /dev/null \
      --user $api_user:$api_secret \
      $JENKINS_URL/$path/build?delay=0sec \
        && echo "Triggered build at $path" \
        || echo "Error triggering build at $path"
  }

}


trigger_builds_from_table()
{
  test -n "$1" || err "triggers tab file expected" 1
  test -z "$2" || err "surplus args: '$2'" 1

  local \
    id_offset=$(fixed_table_hd_offsets $1 PROJECT PROJECT) \
    params_offset=$(fixed_table_hd_offsets $1 PROJECT PARAMS) \
    params_vars= job_id=

  read_nix_style_file $1 | while read line
  do

    # Like create-jenkins-jobs.sh, allow PROJECT col to cross PARAMS col if no params required
    test "  " != "$(echo "$line" | cut -c$(( $params_offset - 1 ))-$params_offset)" && {
      job_id="$(echo $line)"
      params_vars=
    } || {
      job_id="$(echo "$line" | cut -c1-$params_offset )"
      params_vars="$(echo "$line" | cut -c$(( $params_offset + 1 ))- )"
    }

    trigger_build $job_id $params_vars

  done
}


