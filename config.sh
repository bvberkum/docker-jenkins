#!/bin/sh

set -e

scriptname=config
test -n "$tag" || . ./vars.sh "$@"

type err >/dev/null 2>&1 || { . ./util.sh; }


export cname


info "Configuration (chostname=$chostname, JENKINS_URL=$JENKINS_URL)"


trueish "$Config_Init_Keys" && {
  note "Initializing keys"

  docker exec -u jenkins $cname mkdir -vp $chome/.ssh/ \
    || error "Error creating .ssh folder in user homedir" 1


  info "Adding keys from DCKR_VOL ($DCKR_VOL/ssh)"

  test -e $DCKR_VOL/ssh && {


    docker cp $DCKR_VOL/ssh/id_?sa $cname:$chome/.ssh/
    docker cp $DCKR_VOL/ssh/id_?sa.pub $cname:$chome/.ssh/
    docker cp $DCKR_VOL/ssh/authorized_keys $cname:$chome/.ssh/

  } || error "No keydir found, skipped ($DCKR_VOL/ssh)"


  trueish "$Build_Docker_Machine" && {

    # Copy certificate from docker-machine for TLS connection to docker

    info "Adding docker-machine certificates from '$DOCKER_MACHINE_NAME'"

    docker exec -u jenkins -ti $cname bash -c 'mkdir -vp '$chome'/.docker'
    docker exec -u jenkins -ti $cname bash -c 'rm -rf '$chome'/.docker/*.pem'
    docker cp \
      $HOME/.docker/machine/machines/$DOCKER_MACHINE_NAME/ca.pem \
      $cname:$chome/.docker/
    docker cp \
      $HOME/.docker/machine/machines/$DOCKER_MACHINE_NAME/cert.pem \
      $cname:$chome/.docker/
    docker cp \
      $HOME/.docker/machine/machines/$DOCKER_MACHINE_NAME/key.pem \
      $cname:$chome/.docker/

  } || noop


  docker exec -u root $cname chown -R jenkins:jenkins $chome/ 2>/dev/null || {

    info "Error chown $chome/: $? (Operation not permitted)"
  }

  #docker exec -u root $cname chown -R jenkins:jenkins $chome/.ssh/ || noop

  info "SSH folder list:"
  docker exec -u jenkins $cname ls -la $chome/.ssh/
  docker exec -u jenkins $cname test -w $chome/.ssh/authorized_keys || {
    error "Authorized keys is not writable"
  }

}


case "$image_type" in

  # FIXME: probably cleanup everything
  jenkins-server* )

      trueish "$Run_Reset_Volume" && {
      	note "Config run after volume reset"

        #jvm_opts="$(docker exec -ti $cname bash -c 'echo $JAVA_OPTS')"
        #test -z "$jvm_opts" || {
        #  fnmatch "*-Djenkins.install.runSetupWizard=false*" "$jvm_opts" && {
        #    Config_Guided=0
        #  }
        #}
        #echo

        trueish "$Config_Guided" && {

          trueish "$interactive" || {
            error "Guided setup requested (jenkins.install.runSetupWizard=true: $JAVA_OPTS)"
            error "Cannot continue without interactive session" 1
          }

          info "Guided server setup"

          # If no initial user exists, wait for 2.0 automated setup
          docker exec simza-jenkins-server-dev bash -c \
            'test "$JENKINS_HOME/users/*" != "$(echo $JENKINS_HOME/users/*)"' \
            || {

              while true; do
                docker exec $cname test -s $chome/secrets/initialAdminPassword || {
                  info "Waiting for file $chome/secrets/initialAdminPassword..."
                  sleep 15
                  continue
                }
                break
              done

              info "Enter the following key at the web GUI: "
              docker exec $cname cat $chome/secrets/initialAdminPassword
              echo

            info "First, continue the online installer and finish admin setup. "
            clear_env $1
            echo
            info "Key (copy to user > configure > public keys): "
            #docker exec $cname cat $chome/.ssh/id_?sa.pub
            test -e "$ssh_vol" && {
              cat $ssh_vol/id_?sa.pub
            } || {
              cat $DCKR_VOL/ssh/id_?sa.pub
            }
            echo
            info "Press return to continue"
            read _
          }

          get_env $env

          test -n "$api_user" || error "No api-user" 29
          sh ./test.sh test-api-user-nonempty

          trueish "$interactive" && {
            info "Do you want to copy the local JJB config to the container for user $api_user,"
            info "(else generates a new one using the customized init script. )"
            read Build_Copy_JJB
          } || noop

          trueish "$Build_Copy_JJB" && {

            cp /etc/jenkins_jobs/jenkins_jobs.ini /tmp/jenkins_jobs.ini
            sed -i.bak 's/^url=.*/url=http:\/\/localhost:8080/' /tmp/jenkins_jobs.ini
            sed -i.bak 's/^user=.*/user='$api_user'/' /tmp/jenkins_jobs.ini
            sed -i.bak 's/^password=.*/password='$api_secret'/' /tmp/jenkins_jobs.ini
            docker cp /tmp/jenkins_jobs.ini $cname:/etc/jenkins_jobs/jenkins_jobs.ini
            info "Copied local JJB config into container with updated URL"

          }  || {

            docker exec -ti $cname /opt/dotmpe/docker-jenkins/init.sh \
              init_api localhost:8080 $api_user $api_secret \
                > /etc/jenkins_jobs/jenkins_jobs.ini
          }

          echo
          #info "Jenkins Job builder config:"
          #echo
          #docker exec -ti $cname cat /etc/jenkins_jobs/jenkins_jobs.ini \
          #  | sed 's/localhost:8080/'$chostname'/'
          #echo
          trueish "$interactive" && {
            echo
            info "Enter the Press return to continue"
            read _
          } || noop

        } || {

          # 1.* and no-wizard setup
          info "Automated config.."
        }


        # Wait a bit for HTML UI to load?
        info "Fetching $JENKINS_URL/login"
        curl -D - -sf -L -o /dev/null $JENKINS_URL/login || {
          while true
          do
            info "Waiting for HTML UI... ($JENKINS_URL/login)"
            sleep 15
            curl -D - -sf -L -o /dev/null $JENKINS_URL/login \
              && break
          done
        }


        # Add initial jenkins credential to contact CLI, replace in update.sh
        # using cli grooby.

        export JENKINS_URL

        ssh_credentials_id="${hostname}-docker-ssh-key"

        # FIXME: also need to add public key to user for initial CLI setup to
        # work
        for pubkey in $DCKR_VOL/ssh/id_?sa.pub
        do
          test -e "$pubkey" || err "Expected SSH key in $jenkins_home" 1
          log "Found pubkey $pubkey"
          docker exec -ti $cname \
              /opt/dotmpe/docker-jenkins/init.sh add-user-public-key \
              jenkins \
              "$(cat $pubkey)" \
                && log "Added user public key $pubkey for jenkins" \
                || err "Failed adding user pubkey $pubkey" 1
        done

        #log "Creating ~/.ssh/ credentials ID"
        #./script/sh/create-jenkins-ssh-host-credentials.sh \
        #    jenkins "$(hostname) Host SSH Key" $ssh_credentials_id \
        #    && log "Initial credentials succesfully created"

      } || noop
    ;;

esac


