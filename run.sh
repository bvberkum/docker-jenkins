#!/bin/sh

# Id: docker-jenkins-mpe/0.0.1 run.sh

. ./util.sh
test -n "$scriptname" || scriptname=run

test -n "$1" && tag="$1" || tag=latest
test -n "$2" && port="$1" || port=8007

test -n "$image_name" || image_name=jenkins-mpe:$tag

test -n "$pref" || pref=$(hostname -s)_
test -n "$container_name" || container_name=${pref}jenkins
	
test -n "$DCKR_CONF" || DCKR_CONF=~/.conf/dckr/
test -n "$DCKR_VOL" || DCKR_VOL=/Volumes/dckr

test -e "$DCKR_CONF" || err "Missing docker config dir $DCKR_CONF" 1
test -e "$DCKR_VOL" || err "Missing docker volumes dir $DCKR_VOL" 1


container=$(sudo docker ps -a | grep '\<'$container_name'\>' | cut -f1 -d' ')
test -n "$container" && {
  log "Forcing remove of (possibly running) container"
  sudo docker rm -f $container
}

#file:/var/jenkins_home/init.groovy.d/executors.groovy
cp executors.groovy $DCKR_VOL/jenkins/init.groovy.d/executors.groovy

dckr_run()
{
  log "Starting new container for $container_name"

  sudo docker run \
    -p $port:8080 \
    -v $DCKR_VOL/ssh:/docker-ssh:ro \
    -v $DCKR_VOL/jenkins:/var/jenkins_home:rw \
    -v /etc/localtime:/etc/localtime:ro \
    $@ \
    --name $container_name \
    $image_name
}

#dckr_exec()
#{
#  sudo docker exec -t $container_name $@
#}
#
#dckr_cp()
#{
#  test -z "$2" && p=$2 || p=$1
#  sudo docker cp -t $1 $container_name:$p
#}

test "$scriptname" = "run" && {
  case "$1" in
    '')
      dckr_run -d
      ;;
    int*)
      dckr_run -ti
      ;;
    -h*|help*)
      echo "Usage $scriptname [|int(eractive)|-h|help]"
      ;;
    *)
      ;;
  esac
}


