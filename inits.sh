#!/bin/sh

set -e

test -n "$1" || set -- '-' "$1" "$2"
test -n "$2" || set -- "$1" dev "$3"
test -n "$3" || set -- "$1" "$2" latest

# act env tag
act="$1"
shift

case "$act" in

  1* | vanilla )

    # Test-running official jenkins image, however:
    # - Want JJB and supported Jenkins plugins
    # - Extra tools, Docker-in-Docker [DinD], requires custom build anyway.

    image_type=jenkins
    tag=latest
    image_ref=jenkins:$tag
    . ./vars.sh "$@"
    # forcibly remove existing named container
    dckr_run_f=-dt
    container=$(docker ps -a | grep '\<'$cname'\>' | cut -f1 -d' ')
    test -n "$container" && {
      log "Forcing remove of (possibly running) container"
      docker rm -f $container
    }
    docker run $dckr_run_f \
      -m 768M --cpuset-cpus=0 \
      --env JAVA_OPTS="-Dhudson.footerURL=http://github.com/dotmpe/docker-jenkins" \
      -p 8001:8080 \
      -v /etc/localtime:/etc/localtime:ro \
      --hostname $chostname \
      --name $cname \
      $image_ref
  ;;
esac

case "$act" in

  - | 2* | server | server-bvberkum )

      echo "inits: server|server-bvberkum"

      # Suport for Pipeline DSL, DinD, Jenkins Job builder

      #dckr_run_f=" -m 768M --cpuset-cpus=0" \
      Run_Reset_Volume=1 \
      vendor=bvberkum \
      ./init.sh "$@"

    ;;
esac

case "$act" in

  3* | slave-evarga )

      echo "inits: slave-evarga"

      # XXX: Build_Only=1
      vendor=bvberkum \
      dckrfile_dir=jenkins-slave/evarga \
      ./init.sh "$@"
  ;;
esac

case "$act" in

  slave-evarga-dind )

      echo "inits: slave-evarga-dind"
      vendor=bvberkum \
      dckrfile_dir=jenkins-slave/evarga/dind \
      ./init.sh "$@"
    ;;
esac

case "$act" in

  - | slave )

      echo "inits: slave-mpe"
      Build_Only=0 \
      Run_Reset_Volume=1 \
      vendor=bvberkum \
      dckrfile_dir=jenkins-slave/dotmpe \
      ./init.sh "$@"
    ;;
esac

case "$act" in

  - | slave-dind )

      echo "inits: slave-dind"
      Build_Only=1 \
      Run_Reset_Volume=1 \
      vendor=bvberkum \
      dckrfile_dir=jenkins-slave/dotmpe/dind \
      ./init.sh "$@"
    ;;
esac

