#!/bin/sh

# Start fresh jenkins-mpe container with name, destroying previous instance with
# name.

# Id: docker-jenkins/0.0.4-dev run.sh

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


trueish "$Run_Reset_Volume" && {
  trueish "$Run_Home_Container" && {
    docker volume rm jenkins-$env-home || noop
    docker volume create --name jenkins-$env-home
    note "Recreated jenkins-$env-home volume"
  } || {
    note "Need sudo to truncate volume"
    sudo rm -rf $jenkins_home
    note "Truncated jenkins_home volume ($jenkins_home)"
  }
} || noop


trueish "$Run_Home_Container" \
  || mkdir -vp $jenkins_home


# TODO: copy prod to acc volume
#test -z "$Run_Copy_Home_Volume" || {
#  docker run --rm --volumes-from $Run_Copy_Home_Volume \
#    -v busybox tar cvf /src_home $chome
#}



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

        # Preconfigure jenkins home folder using temporary container

        docker run -dt --name jnk-vol-tmp -v jenkins-$env-home:$jenkins_home --entrypoint "cat" ubuntu \
          || error "Failed starting jnk-vol-tmp" 1

        docker exec jnk-vol-tmp mkdir -vp $jenkins_home/.ssh $jenkins_home/init.groovy.d/

        #cp log-parser-rules.txt $jenkins_home

        docker cp script/executors.groovy jnk-vol-tmp:$jenkins_home/init.groovy.d/executors.groovy

        {
          echo "# Parameters for init.groovy.d/setup-user-security.groovy"
          echo Build_Admin_User="'$Build_Admin_User'"
          echo Build_Admin_Password="'$Build_Admin_Password'"
          echo Build_Admin_Public_Key="'$(cat $DCKR_VOL/ssh/id_?sa.pub)'"
        } > setup-user-security.init

        docker cp setup-user-security.init jnk-vol-tmp:$jenkins_home/init.groovy.d/setup-user-security.init
        docker cp script/setup-user-security.groovy jnk-vol-tmp:$jenkins_home/init.groovy.d/setup-user-security.groovy

        test -e custom/ && docker cp custom/ jnk-vol-tmp:$jenkins_home/custom

	rm setup-user-security.init

        docker rm -f jnk-vol-tmp

      ;;

    jenkins-slave* )
      ;;

  esac
}


note "Starting new container"
preconfig
dckr_run

export cid=$cid

