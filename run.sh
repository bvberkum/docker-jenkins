#!/bin/sh

# Start fresh jenkins.mpe container with name, destroying previous instance with
# name.

# Id: docker-jenkins/0.0.2 run.sh

set -e

scriptname=run

test -n "$tag" || . ./vars.sh "$@"


# forcibly remove existing named container
trueish "$Build_Destroy_Existing" && {
  test -n "$cid" && {
    log "Forcing remove of existing container ($cname, $cid)"
    docker rm -f $cid
  }
  cid=
} || noop

trueish "$Run_Reset_Volume" && {
  rm -rf $jenkins_home
  log "Truncated jenkins_home volume ($jenkins_home)"
} || noop

mkdir -vp $jenkins_home


dckr_run()
{
  log "Starting new container for $cname"

  test -e $image_type/run.sh && {
    . ./$image_type/run.sh
  }

  test -e $env_vars_file && {
    log "Using env-file $env_vars_file"
    dckr_run_f="$dckr_run_f --env-file ./$env_vars_file"
  }

  log "Running: 'docker run $dckr_run_f \
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
  log "Pre-configure"

  case "$image_type" in

    jenkins-server* )

        #cp log-parser-rules.txt $jenkins_home

        mkdir -vp $jenkins_home/init.groovy.d/

        cp script/executors.groovy $jenkins_home/init.groovy.d/executors.groovy

        {
          echo Build_Admin_User="'$Build_Admin_User'"
          echo Build_Admin_Password="'$Build_Admin_Password'"
          echo Build_Admin_Public_Key="'$(cat $DCKR_VOL/ssh/id_?sa.pub)'"
        } > setup-user-security.init
        mv setup-user-security.init $jenkins_home/init.groovy.d/
        cp script/setup-user-security.groovy $jenkins_home/init.groovy.d/setup-user-security.groovy

        test -e custom/ && cp -r custom/ $jenkins_home/custom
      ;;

    jenkins-slave* )
      ;;

  esac
}


log "Default run"
preconfig
dckr_run_f="$dckr_run_f -d"
dckr_run
export cid=$cid

