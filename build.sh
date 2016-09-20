#!/bin/sh

# Id: docker-jenkins/0.0.2 build.sh

scriptname=build

test -n "$tag" || . ./vars.sh "$@"

set -e


# remove previous images and containers using this repository+tag
docker images | grep ^$image_ref && {

  true "$Build_Remove_Existing" && {
    # TODO: see about deleting all layers in image

    container=$(docker ps -a | grep '\s\<'$cname'\>[\s$]*' | cut -f1 -d' ')
    #test -n "$container" && {
    #  echo "Forcing remove of (possibly running) container"
    #  docker rm -f $cname
    #}

    docker rmi -f $image_ref

  } || {

    err "Image already exists."
  }

}


log "Building new image for $image_ref"

case "$image_type" in

  jenkins-server* )

      sed -i.bak 's/FROM jenkins:.*/FROM jenkins:'$tag'/' $dckrfile

      trueish "$guided_server_setup" \
        || dckr_build_f=" --build-arg jenkins_install_wizard=false "

    ;;

#  jenkins-slave )
#    ;;

esac


docker build $dckr_build_f \
  $build_args \
  -f $dckrfile \
  -t $image_ref \
  .


# XXX: git checkout $dckrfile



