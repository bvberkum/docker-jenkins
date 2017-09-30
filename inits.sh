#!/bin/sh
set -e
type noop >/dev/null 2>&1 || . ./util.sh

# args: ACT ENV TAG
test -n "$1" || set -- '-' "$1" "$2"
test -n "$2" || set -- "$1" dev "$3"
test -n "$3" || set -- "$1" "$2" latest

act="$1"
shift
log "Starting '$act' init.."

case "$act" in

  1* | vanilla )

    # Test-running official jenkins image, however:
    # - Want JJB and supported Jenkins plugins
    # - Extra tools, Docker-in-Docker [DinD], requires custom build anyway.

    Build_Image=0
    image_type=jenkins
    image_ref=jenkins:$tag
    docker run $dckr_run_f \
      -m 768M --cpuset-cpus=0 \
      --env JAVA_OPTS="-Dhudson.footerURL=http://github.com/bvberkum/docker-jenkins" \
      -p 8001:8080 \
      -v /etc/localtime:/etc/localtime:ro \
      --hostname $chostname \
      --name $cname \
      $image_ref
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

  - | slave-mpe | slave )

      echo "inits: slave-mpe"
      vendor=bvberkum \
      dckrfile_dir=jenkins-slave/dotmpe \
      ./init.sh "$@"
    ;;
esac

case "$act" in

  - | slave-mpe-dind | slave-dind )

      echo "inits: slave-dind"
      Build_Only=1 \
      vendor=bvberkum \
      dckrfile_dir=jenkins-slave/dotmpe/dind \
      ./init.sh "$@"
    ;;
esac

case "$act" in

  - | 2* | server | server-bvberkum )

      git clean -dfx
      echo "inits: server|server-bvberkum"

      # Suport for Pipeline DSL, DinD, Jenkins Job builder

      #dckr_run_f=" -m 768M --cpuset-cpus=0" \
      vendor=bvberkum \
      ./init.sh "$@"

    ;;
esac

log "Inits done"
