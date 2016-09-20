#!/bin/sh

type noop 2>&1 >/dev/null || . ./util.sh

test -n "$api_user" || get_env
test -n "$JENKINS_URL" || exit 130


generate_job()
{
  test -n "$1" || err "job-type expected" 1
  test -z "$4" || err "surplus args: '$4'" 1

  log "generate-job: 1:$1 2:$2 3:$3"
  case "$1" in

    cb-folder )
        export NAME= ID= DISPLAY_NAME= DESCRIPTION=
        eval $env_vars
        export $(echo $env_vars | sed 's/="[^"]*"//g')

        . ./script/sh/create-item-cb-folder.sh \
          && log "Created folder ($3)" \
          || { 
		err "failed creating folder ($3)"; 
		return 2; 
          }
      ;;

    jtb-prepare-preset )
        docker exec $cname /opt/dotmpe/docker-jenkins/init.sh \
          init_jtb_preset $2 $3 || return $?
      ;;

    jtb-update-preset )
        docker exec $cname bash -c \
          'jenkins-jobs update $JTB_SRC_DIR/'$(echo $2)'.yaml:$JTB_SRC_DIR/dist/base.yaml' \
            || return $?
      ;;

    jtb-preset )
        generate_job jtb-prepare-preset "$2" "$3" \
            && log "Generated preset $2 ($3)" \
            || {
              err "Failed creating preset $2 ($3)"
              return
            }

        generate_job jtb-update-preset "$2" "$3" \
            && log "Updated $1 project $2" \
            || err "Failed updating $1 project $2"

        docker exec $cname bash -c 'rm $JTB_SRC_DIR/'$(echo $2)'.yaml'
      ;;

    jtb )
        test -n "$2" || err "args expected" 1
        test -e "$2" && {
          # Copy local file to container
          name=$(basename $(basename $2 .yml) .yaml)
          docker cp $2 $cname:/tmp/$name.yml
          path='/tmp/'$name'.yml'
        } || {
          # Assume it is a path in the container
          path=$2
        }
        ./jenkins-user-script.sh reconfigure_jtb_job \
            $path \
            && log "Updated $1 project config $2" \
            || err "Failed updating $1 project config $2"
        test ! -e "$2" || {
          docker exec -u root $cname rm $path
        }
      ;;

    jtb-gh-travis )
        generate_job jtb-prepare-preset "generic-gh-travis" "$3" \
            && log "Generated GitHub/Travis preset $2 ($3)" \
            || {
              err "Failed creating GitHub/Travis preset $2 ($3)"
              return
            }
        docker exec $cname bash -c \
          'jenkins-jobs update $JTB_SRC_DIR/generic-gh-travis.yaml:$JTB_SRC_DIR/dist/base.yaml '$2 \
            || err "Update GitHub/Travis job $2 failed"
        docker exec $cname bash -c 'rm $JTB_SRC_DIR/generic-gh-travis.yaml'
      ;;

    jtb-presets )
        # TODO: generate_job jtb-preset
      ;;

    git-jtb )
        # TODO: generate_job git-jtb
      ;;

    jjb )
        test -n "$jjb_config" || err "No jjb_config" 1
        test -e "$jjb_config" || err "No jjb_config" 1
	which jenkins-jobs >/dev/null 2>&1 || error "Local jenkins-jobs install required" 1
        test -e "$2" || { err "No JJB file '$2'"; return 1; }
        jenkins-jobs --conf $jjb_config update $2 \
          && log "Updated $1 project config $2" \
          || err "Failed updating $1 project config $2"
      ;;

    * )
        err "No such job type: $1" 1
      ;;

  esac
}

generate_jobs_from_tab()
{
  test -n "$1" || err "projects tab file expected" 1
  test -z "$2" || err "surplus args: '$2'" 1

  local \
    type_offset=$(fixed_table_hd_offsets $1 TYPE TYPE) \
    args_offset=$(fixed_table_hd_offsets $1 TYPE ARGS) \
    env_offset=$(fixed_table_hd_offsets $1 TYPE ENV) \
    env_vars= args_var= job_type=

  read_nix_style_file $1 | while read line
  do

    job_type="$(echo "$line" | cut -c1-$args_offset)"

    # Parse only args, no env, if args len is beyond env_offset.
    # Otherwise parse both.

    test "  " != "$(echo "$line" | cut -c$(( $env_offset - 1 ))-$env_offset)" && {

      args_var="$(echo "$line" | cut -c$(( $args_offset + 1 ))-)"
      env_vars=""

    } || {

      args_var="$(echo "$line" | cut -c$(( args_offset + 1 ))-$env_offset)"
      env_vars="$(echo "$line" | cut -c$(( $env_offset + 1 ))-)"

      test -z "$(echo $env_vars)" || {
        eval $env_vars
        export $(echo $env_vars | sed 's/="[^"]*"//g')
      }
    }

    args_var="$(eval echo "$args_var")"

    generate_job $job_type "$args_var" "$env_vars" || {
      sleep 2
    }
  done

}

