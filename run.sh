#!/bin/sh

# Start fresh jenkins-mpe container with name, destroying previous instance with
# name.

# Id: docker-jenkins/0.0.5-dev run.sh

set -e

scriptname=run

test -n "$tag" || . ./vars.sh "$@"


# forcibly remove existing named container
trueish "$Build_Destroy_Existing" && {
  test -n "$cid" && {
    note "Forcing remove of existing container ($cname, $cid)"
    docker rm -f $cid
  }
  cid=
} || noop



dckr_run()
{
  note "Starting new container for $cname"

  test -e $image_type/run.sh && {
    . ./$image_type/run.sh
  }

  test -e $env_vars_file && {
    note "Using env-file $env_vars_file"
    dckr_run_f="$dckr_run_f --env-file ./$env_vars_file"
  }

  note "Running: 'docker run $dckr_run_f \
    -v /etc/localtime:/etc/localtime:ro \
    --hostname $chostname \
    --name $cname \
    $image_ref'"

  cid=$(docker run $dckr_run_f \
    -v /etc/localtime:/etc/localtime:ro \
    --hostname $chostname \
    --name $cname \
    $image_ref)

  which jsotk.py 1>/dev/null 2>&1 && {
    docker inspect $cname | \
      jsotk.py --pretty -O yaml objectpath - '$..*[@.Ports]'
  }
}

preconfig()
{
  note "Pre-configure"

  case "$image_type" in

    jenkins-server* )

        trueish "$Run_Reset_Volume" && {
          trueish "$Run_Home_Container" && {
            docker volume rm $data_container_name || noop
            docker volume create --name $data_container_name
            note "Recreated $data_container_name volume"
          } || {
            note "Need sudo to truncate volume, g0t r00t?"
            sudo rm -rf $jenkins_home
            note "Truncated jenkins_home volume ($jenkins_home)"
          }
        } || noop


        trueish "$Run_Home_Container" \
          || mkdir -vp $jenkins_home


        trueish "$Run_Reset_Volume" && {

          # Preconfigure jenkins home folder using temporary container

          docker run -dt \
            -v $data_container_name:$chome \
            --name jnk-vol-$env-tmp \
            --entrypoint "cat" ubuntu \
              || error "Failed starting jnk-vol-$env-tmp" 1


          test -n "$Run_Import_Home_Volume" && {

            # Import from tar

            basename=$(basename $Run_Import_Home_Volume)

            docker run --rm \
              -v $data_container_name:$chome \
              -v $(pwd)/$Run_Import_Home_Volume:/tmp/$basename \
              busybox tar x \
                -f /tmp/$basename $chome \
                  && note "Imported jenkins-home folder from $basename" \
                  || error "Import jenkins-home error: $?" $?

          } || {

            test -n "$Run_Copy_Home_Volume" && {

              # Import from another volume?
              error "FIXME: cannot mount directly, mount paths would be identical" 1
              # export first, then import
              #docker run --rm \
              #  -v $Run_Copy_Home_Volume:/ \
              #  busybox rsync -avzui /rc_home $chome

            } || {

              note "Pre-configuring standard customizations"

              docker exec jnk-vol-$env-tmp mkdir -vp $jenkins_home/.ssh $jenkins_home/init.groovy.d/

              docker cp script/setup-executors.groovy jnk-vol-$env-tmp:$jenkins_home/init.groovy.d/setup-executors.groovy

              {
                echo "// Parameters for init.groovy.d/setup-user-security.groovy"
                echo Build_Admin_User="'$Build_Admin_User'"
                echo Build_Admin_Password="'$Build_Admin_Password'"
                echo Build_Admin_Public_Key="'$(cat $DCKR_VOL/ssh/id_?sa.pub)'"
              } > setup-user-security.init

              docker cp setup-user-security.init jnk-vol-$env-tmp:$jenkins_home/init.groovy.d/setup-user-security.init
              docker cp script/setup-user-security.groovy jnk-vol-$env-tmp:$jenkins_home/init.groovy.d/setup-user-security.groovy
              rm setup-user-security.init

              docker cp custom/ jnk-vol-$env-tmp:$jenkins_home/custom

              docker cp custom/org.codefirst.SimpleThemeDecorator.xml \
                jnk-vol-$env-tmp:$jenkins_home/org.codefirst.SimpleThemeDecorator.xml
            }
          }
        }

        docker exec -ti jnk-vol-$env-tmp chown -R 1000:1000 $jenkins_home/

        docker rm -f jnk-vol-$env-tmp

      ;;

    jenkins-slave* )
      ;;

  esac
}


note "Starting new container"
preconfig
dckr_run

export cid=$cid

