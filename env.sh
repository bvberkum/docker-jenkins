#!/bin/sh
set -e

case "$(hostname -s)" in

  simza* )
      case "$env" in
        acc )
            DOTMPE_SLAVE_HOST=192.168.9.101
          ;;
        dev )
            DOTMPE_SLAVE_HOST=192.168.9.100
          ;;
      esac
      DOCKER_URL="$(echo $DOCKER_HOST | sed 's/tcp/https/' )"
    ;;

  dandy )
      DANDY=192.168.9.3
      DOTMPE_SLAVE_HOST=$DANDY
      DOCKER_URL=http://$DANDY:2375
    ;;

  vs1 )
      VS1=192.168.9.31
      DOTMPE_SLAVE_HOST=$VS1
      DOCKER_URL=http://$VS1:2375

    ;;

esac

