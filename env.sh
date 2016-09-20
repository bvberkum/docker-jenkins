#!/bin/sh
set -e

log "Hostname: $hostname"

case "$hostname" in

  dandy )
      DANDY=192.168.9.3
      DOTMPE_SLAVE_HOST=$DANDY
      DCKR_SWARM_URL=http://$DANDY:2375
    ;;

  vs1 )
      VS1=192.168.9.31
      DOTMPE_SLAVE_HOST=$VS1
      DCKR_SWARM_URL=http://$VS1:2375

    ;;

  trusty64_docker_vagrant_boreas_mpe )

      ##export DCKR_VOL=/srv/docker-local

      #export DCKR_HOST=localhost
      # Need private_network with IP assigned
      export DCKR_HOST="$(ifconfig eth1 | grep 'inet\>' | sed 's/.*addr:\([^\ ]*\).*$/\1/')"

      test -n "$DCKR_HOST" || error "Missing DCKR_HOST env" 1
      log "Docker Host: $DCKR_HOST"

      export DOTMPE_SLAVE_HOST=$DCKR_HOST
      export DCKR_SWARM_URL=http://${DCKR_HOST}:2375

      export DOTMPE_SLAVE_HOST=$DCKR_HOST
#      export DOTMPE_SLAVE_PORT=2001
#      export DOTMPE_DIND_SLAVE_PORT=2002

      log "Set inits host vars ($hostname)"
    ;;

  boreas* )

      case "$env" in
        acc )
            DOTMPE_SLAVE_HOST=192.168.9.101
          ;;
        dev )
            DOTMPE_SLAVE_HOST=192.168.9.100
          ;;
      esac

      export verbosity=6

      export Build_Chmod=ugo+rw
      #export Build_Chown=1000:1000
      export Build_Chown=jenkins:staff
      export chostname=localhost
      export Build_URL_Include_Port=1
      #export JENKINS_URL=https://localhost:8007

      api_user=jenkins

      eval $(domain show-env domain_)
      test -n "$domain_network" || exit 18

      case "$domain_network" in
        work ) eth_port=en0 ;;
        prive ) eth_port=en5 ;;
      esac
      test -n "$eth_port" || exit 19

      export DCKR_HOST=$(echo $(ifconfig $eth_port | grep 'inet\ ') | cut -d ' ' -f 2)
      test -n "$DCKR_HOST" || exit 20
      export DOTMPE_SLAVE_HOST=$DCKR_HOST
      export DCKR_SWARM_URL=http://${DCKR_HOST}:2375

      curl -S localhost:2375/_ping \
        || nohup socat -4 TCP-LISTEN:2375,fork UNIX-CONNECT:/var/run/docker.sock &

    ;;

  dckr-test )

      VERBOSE=1
      export DCKR_VOL=$(pwd)/volumes
      export DCKR_CONF=$(pwd)/config
      mkdir -vp $DCKR_VOL
      export Build_Chown=jenkins:staff
      export hostname=dckr-test
      export chostname=$hostname-jenkins-server
      export JENKINS_URL=https://$chostname.$(hostname -d)

      log "Set inits host vars ($hostname)"
    ;;


esac

