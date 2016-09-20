#!/bin/sh
set -e

type noop >/dev/null 2>&1 || . ./util.sh


test -x "$(which docker)" || error "Docker client missing" 1

test -n "$hostname" || hostname="$(hostname -s | tr 'A-Z.-' 'a-z__')"
test -n "$verbosity" || export verbosity=6


# Require paths to docker volumes
test -n "$DCKR_CONF" || DCKR_CONF=~/.conf/dckr/
test ! -e "$DCKR_CONF/$hostname/vars.sh" || {
  . $DCKR_CONF/$hostname/vars.sh
}
test -n "$DCKR_VOL" || DCKR_VOL=/Volumes/dckr

test -n "$VERBOSE" && {
  test ! -e "$DCKR_CONF" || info DCKR_CONF=$DCKR_CONF
  info DCKR_VOL=$DCKR_VOL
}


# Get tag, image and container names
test -n "$1" && { env="$1"; incr_c; shift 1; } || test -n "$env" || env=dev
test -n "$1" && { tag="$1"; incr_c; shift 1; } || test -n "$tag" || tag=latest

test -n "$vendor" || vendor=dotmpe
test -n "$dckrfile_dir" || dckrfile_dir=jenkins-server
test -n "$dckrfile" || dckrfile="$dckrfile_dir/Dockerfile"
test -n "$dckr_run_f" || dckr_run_f="-d"
test -n "$image_type" || image_type=$(echo $dckrfile_dir | tr '/' '-')
test -n "$shostname" || shostname=$image_type
test -n "$image_ref" || image_ref=$vendor/$image_type:$tag
test -n "$env_vars_file" || env_vars_file=.$image_type-env-$env.sh
test -n "$env" || error "No env given" 1
test -n "$tag" || error "No tag given" 1

case "$image_type" in

  jenkins-server* )

    #test -n "$Config_Wizard" || Config_Wizard=0
    test -n "$Config_Guided" || Config_Guided=0

    # Guided setup needs an agent at the terminal
    tty -s && interactive=1 || interactive=
    trueish "$interactive" || {
      test -n "$Build_Copy_JJB" || Build_Copy_JJB=0
      trueish "$Config_Guided" \
        && error "Cannot do interactive setup without console"
    }
  ;;
esac

# Default build options
test -n "$Build_Image" || Build_Image=1
test plugins.txt -nt plugins_default.txt || {
  test -x "$(which jsotk.py)" \
    && Recompile_Plugins=1 \
    || warn "Cannot update plugins.txt"
}
test -n "$Build_Offline" || Build_Offline=0
trueish "$Build_Offline" && {
  test -n "$Update_Packages" || Update_Packages=0
  test -n "$Update_Plugins" || Update_Plugins=0
} || {
  test -n "$Update_Packages" || Update_Packages=1
  test -n "$Update_Plugins" || Update_Plugins=1
}
test -n "$Build_Only" || Build_Only=0
test -n "$Run_Reset_Volume" || Run_Reset_Volume=1
trueish "$Run_Reset_Volume" && {
  test -n "$Build_Destroy_Existing" || Build_Destroy_Existing=1
} || {
  test -n "$Build_Destroy_Existing" || Build_Destroy_Existing=0
}
test -n "$Run_Home_Container" || Run_Home_Container=1
test -n "$Build_Config" || Build_Config=1
test -n "$Config_Init_Keys" || Config_Init_Keys=1
test -n "$Build_Updates" || Build_Updates=1
test -n "$Update_Customizations" || Update_Customizations=1
test -n "$Update_Credentials" || Update_Credentials=1
test -n "$Update_Credentials_Clear" || Update_Credentials_Clear=1
test -n "$Update_Clouds" || Update_Clouds=1
test -n "$Update_Cloud_Clear" || Update_Cloud_Clear=1
test -n "$Update_Nodes" || Update_Nodes=1
test -n "$Update_Projects" || Update_Projects=1
test -n "$Update_Views" || Update_Views=1
test -n "$Build_Triggers" || Build_Triggers=1
test -n "$Build_Admin_User" || Build_Admin_User=jenkins
test -n "$Build_Admin_Password" || Build_Admin_Password=jenkins
test -n "$Build_Copy_JJB" || Build_Copy_JJB=0
test -n "$Build_URL_Include_Port" || Build_URL_Include_Port=1

test -n "$JTB_TAG" || JTB_TAG=dev
test -n "$JJB_TAG" || JJB_TAG=build


# Check if requested env matches with current docker server

test -n "$(which docker-machine)" -a -x "$(which docker-machine)" && {
  test -n "$DOCKER_MACHINE_NAME" && {
    test "$env" = "$DOCKER_MACHINE_NAME" \
      || error "Current docker-machine is '$DOCKER_MACHINE_NAME', not '$env'" 1
    Build_Docker_Machine=1
  } || {

    docker-machine ls | grep -q '\<'$env'\>' && {
      eval $(docker-machine env $env)
      env | grep DOCK
      info "Using docker-machine '$env'"
      Build_Docker_Machine=1
    } || noop
  }
} || {
  note "No docker-machine, proceeding with current docker client assuming env is $env"
}


# Assemble docker arguments: hostname, container name, volumes, env, etc.

case "$env" in

  prod )
      test -n "$jenkins_home" || jenkins_home=$DCKR_VOL/$image_type
      test -n "$chostname" || chostname=$shostname.$(hostname -f)
      test -n "$cname" || cname=$hostname-$shostname
    ;;

  * )
      test -n "$jenkins_home" || jenkins_home=$DCKR_VOL/$image_type-$env
      test -n "$chostname" || chostname=$shostname-$env.$(hostname -f)
      test -n "$cname" || cname=$hostname-$shostname-$env
    ;;

esac



## "DIND"

case "$image_type" in

  *jenkins-server* )
      test -n "$Build_Dind" || Build_Dind=1
      test -n "$Build_Dind_Share" || Build_Dind_Share=1
    ;;

  *dind* )
      test -n "$Build_Dind" || Build_Dind=1
      test -n "$Build_Dind_Share" || Build_Dind_Share=1
    ;;

esac


## Env specific values

case "$env" in

  dev )

      test -n "$Run_Reset_Volume" || Run_Reset_Volume=1
      test -n "$Build_Destroy_Existing" || Build_Destroy_Existing=1
    ;;

esac

case "$env" in
  # Expose port for easy inspection
  dev )
      DOTMPE_SLAVE_PORT=2005
      DOTMPE_SLAVE_DIND_PORT=2003
    ;;
  acc )
      DOTMPE_SLAVE_PORT=2006
      DOTMPE_SLAVE_DIND_PORT=2004
    ;;
  prod )
      DOTMPE_SLAVE_PORT=2001
      DOTMPE_SLAVE_DIND_PORT=2002
    ;;
  * )
      #DOTMPE_SLAVE_PORT=22
    ;;
esac


## Image-type/env specific values

case "$image_type" in


  jenkins-server* )

      chome=/var/jenkins_home

      case "$env" in

        dev )
            test -z "$JJB_SRC_DIR" || dckr_run_f="$dckr_run_f -v $JJB_SRC_DIR:/srv/project-local/jenkins-job-builder:rw"
            test -z "$JTB_SRC_DIR" || dckr_run_f="$dckr_run_f -v $JTB_SRC_DIR:/srv/project-local/jenkins-templated-builds:rw"
          ;;

      esac


      ### Web access

      test -n "$Build_Static_Web_Port" || Build_Static_Web_Port=1
      trueish "$Build_Static_Web_Port" && {

        test -n "$web_port" || case "$env" in
          prod ) web_port=8007 ;;
          acc )  web_port=8017 ;;
          dev )  web_port=8027 ;;
          * )    web_port=8077 ;;
        esac

        dckr_run_f="$dckr_run_f -p $web_port:8080"

      } || noop

      test -n "$Build_HTTP_Proxy_Port" || Build_HTTP_Proxy_Port=0
      trueish "$Build_HTTP_Proxy_Port" && {

        # TODO: deal with reverse proxy (maps frontend 80 to 8080 backend)
        web_port=8080
        ext_web_port=80
      }


      info "DCKR_HOST=$DCKR_HOST"

      test -n "$JENKINS_URL" || {

        # Use DCKR_HOST IP to reverse Jenkins HTTP URL
        test -n "$DCKR_HOST" && {
          # cut up tcp url
          fnmatch "tcp:*" $DCKR_HOST && {
            JENKINS_URL=http$(echo ${DCKR_HOST:3} | sed 's/\:2376.*//')
          } || {
          JENKINS_URL=http://$DCKR_HOST
          }
        } || {
          JENKINS_URL=http://$chostname
        }

        trueish "$Build_URL_Include_Port" && {
          JENKINS_URL=$JENKINS_URL:$web_port
        }

        export JENKINS_URL

        info "JENKINS_URL=$JENKINS_URL"
      }

      {
        echo "# Generated at by $0 at $(date)"

        echo JTB_TAG=$JTB_TAG
        echo JJB_TAG=$JJB_TAG

        echo JJB_USER=$Build_Admin_User
        echo JJB_PASSWORD=$Build_Admin_Password

        echo JTB_SRC_DIR=/srv/project-local/jenkins-templated-builds
        echo JJB_SRC_DIR=/srv/project-local/jenkins-job-builder
        #echo JNK_UC_SRC=/srv/project-local/jenkins-userContent

      } > $env_vars_file

      # Run from container or local mount volume
      trueish "$Run_Home_Container" && {
        dckr_run_f="$dckr_run_f -v jenkins-$env-home:$chome:rw"
      } || {
        dckr_run_f="$dckr_run_f -v $jenkins_home:$chome:rw"
      }
    ;;


  jenkins-slave*dind* )

      dckr_run_f="$dckr_run_f -p $DOTMPE_SLAVE_DIND_PORT:22"

      chome=/home/jenkins
      #dckr_run_f="$dckr_run_f -v $jenkins_home:$chome/workspace:rw"
    ;;


  jenkins-slave-dotmpe* )

      dckr_run_f="$dckr_run_f -p $DOTMPE_SLAVE_PORT:22"

      chome=/home/jenkins
      #dckr_run_f="$dckr_run_f -v $jenkins_home:$chome/workspace:rw"
    ;;


  jenkins-slave* )

      chome=/home/jenkins/
      #dckr_run_f="$dckr_run_f -v $jenkins_home:$chome/workspace:rw"
    ;;

esac


#test -n "$ssh_vol" || ssh_vol=$DCKR_VOL/config/$cname.ssh
#test -e "$ssh_vol" && {
#  #log "Adding SSH volume $ssh_vol"
#  test -n "$chome" \
#    ||  error "Container Homedir must be know to mount SSH volume" 1
#  dckr_run_f="$dckr_run_f -v $ssh_vol:$chome/.ssh"
#} || {
#  error "No SSH volume ($ssh_vol)"
#}


## Privileged run

trueish "$Build_Dind" && {
  dckr_run_f=" --privileged
    -v /var/run/docker.sock:/var/run/docker.sock $dckr_run_f "
  trueish "$Build_Dind_Share" && {
    dckr_run_f=" -v /var/lib/docker:/var/lib/docker $dckr_run_f "
  }
}

dckr_run_f=" $dckr_run_f --env VIRTUAL_HOST=$chostname --env VIRTUAL_PORT=8080 "


## Ports

test -n "$Build_Export_Ports" || Build_Export_Ports=1

trueish "$Build_Export_Ports" && {

  dckr_run_f="$dckr_run_f -P"
}


# Experimenting with build tags to configure dependencies
#dckr_build_f="$dckr_build_f --build-arg build_tag=$tag --build-arg build_meta=$env"
test ! -e $env_vars_file || {
  build_args=$(cat $env_vars_file | grep -v '^#' | \
      sed 's/.*/--build-arg\ &/g')
}

test ! -e env.sh \
  || . ./env.sh

. ./build-util.sh

test -e "$image_type/vars.sh" && {
  . $image_type/vars.sh
}


which jenkins-jobs >/dev/null 2>&1 && {
  log "Found jenkins-job-builder installed at $hostname: $(jenkins-jobs --version)"
} || {
  err "No jenkins-job-builder installation, will not be able to update JJB etc. from local host."
}

echo
echo '------------------------------------------------------------------------'
echo
info "Docker $(docker info | grep Version:)"
info "Docker Env $(docker info | grep Name:)"
info "Build Env: $env"
info "Image ID: $image_ref"
info "Build Tag: $tag"
info "Container name/host/http: $cname, $chostname, $web_port"
echo
echo '------------------------------------------------------------------------'

