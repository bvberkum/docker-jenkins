#!/bin/sh

set -e

scriptname=config
test -n "$tag" || . ./vars.sh "$@"

type err >/dev/null 2>&1 || { . ./util.sh; }


export cname

log "Configuration"

trueish "$Run_Reset_Volume" && {

  docker exec $cname ls -la $chome/.ssh

  docker exec -u jenkins $cname test -w $chome/.ssh || {
    echo "Dir is not writable"
  }

  test -n "$ssh_vol" -a -e "$ssh_vol" && {

    log ssh_vol=$ssh_vol
    log $dckr_run_f

  } || {

    log "Adding keys from DCKR_VOL ($DCKR_VOL/ssh)"

    test -e $DCKR_VOL/ssh && {
      (
        docker exec $cname mkdir -vp $chome/.ssh/
        docker cp $DCKR_VOL/ssh/id_?sa $cname:$chome/.ssh/
        docker cp $DCKR_VOL/ssh/id_?sa.pub $cname:$chome/.ssh/
        docker cp $DCKR_VOL/ssh/authorized_keys $cname:$chome/.ssh/

      ) 2>/dev/null || {

        log "Error chown $chome/.ssh: $? (Operation not permitted)"
      }
    } || err "No keydir found, skipped ($DCKR_VOL/ssh)"
  }

  docker exec -u root $cname chown -R jenkins:jenkins $chome/.ssh/ || noop

  docker exec -u jenkins $cname test -w $chome/.ssh/authorized_keys || {
    err "Authorized keys is not writable"
  }


  trueish "$Build_Docker_Machine" && {

    # Copy certificate from docker-machine for TLS connection to docker

    log "Adding docker-machine certificates from '$DOCKER_MACHINE_NAME'"

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

    log "Error chown $chome/: $? (Operation not permitted)"
  }

}

case "$image_type" in

  jenkins-server* )

      trueish "$Run_Reset_Volume" && {

        jvm_opts="$(docker exec -ti $cname bash -c 'echo $JAVA_OPTS')"
        test -z "$jvm_opts" || {
          fnmatch "*-Djenkins.install.runSetupWizard=false*" "$jvm_opts" && {
            guided_server_setup=0
          }
        }

        echo

        trueish "$guided_server_setup" && {

          trueish "$interactive" || {
            err "Guided setup requested (jenkins.install.runSetupWizard=true: $JAVA_OPTS)"
            err "Cannot continue without interactive session" 1
          }

          log "Guided server setup"

          # If no initial user exists, wait for 2.0 automated setup
          docker exec simza-jenkins-server-dev bash -c \
            'test "$JENKINS_HOME/users/*" != "$(echo $JENKINS_HOME/users/*)"' \
            || {

              while true; do
                docker exec $cname test -s $chome/secrets/initialAdminPassword || {
                  log "Waiting for file $chome/secrets/initialAdminPassword..."
                  sleep 15
                  continue
                }
                break
              done

              log "Enter the following key at the web GUI: "
              docker exec $cname cat $chome/secrets/initialAdminPassword
              echo

            log "First, continue the online installer and finish admin setup. "
            clear_env $1
            echo
            log "Key (copy to user > configure > public keys): "
            #docker exec $cname cat $chome/.ssh/id_?sa.pub
            test -e "$ssh_vol" && {
              cat $ssh_vol/id_?sa.pub
            } || {
              cat $DCKR_VOL/ssh/id_?sa.pub
            }
            echo
            log "Press return to continue"
            read _
          }

          get_env $env

          test -n "$api_user" || exit 123
          sh ./test.sh test-api-user-nonempty

          trueish "$interactive" && {
            log "Do you want to copy the local JJB config to the container for user $api_user,"
            log "(else generates a new one using the customized init script. )"
            read Build_Copy_JJB
          } || noop

          trueish "$Build_Copy_JJB" && {

            cp /etc/jenkins_jobs/jenkins_jobs.ini /tmp/jenkins_jobs.ini
            sed -i.bak 's/^url=.*/url=http:\/\/localhost:8080/' /tmp/jenkins_jobs.ini
            sed -i.bak 's/^user=.*/user='$api_user'/' /tmp/jenkins_jobs.ini
            sed -i.bak 's/^password=.*/password='$api_secret'/' /tmp/jenkins_jobs.ini
            docker cp /tmp/jenkins_jobs.ini $cname:/etc/jenkins_jobs/jenkins_jobs.ini
            log "Copied local JJB config into container with updated URL"

          }  || {

            docker exec -ti $cname /opt/dotmpe/docker-jenkins/init.sh \
              init_api localhost:8080 $api_user $api_secret \
                > /etc/jenkins_jobs/jenkins_jobs.ini
          }

          echo
          #log "Jenkins Job builder config:"
          #echo
          #docker exec -ti $cname cat /etc/jenkins_jobs/jenkins_jobs.ini \
          #  | sed 's/localhost:8080/'$chostname'/'
          #echo
          trueish "$interactive" && {
            echo
            log "Enter the Press return to continue"
            read _
          } || noop

        } || {


          # 1.* and no-wizard setup
          log "Automated config.."


          export api_user=$Build_Admin_User
          export api_secret=$Build_Admin_User
          store_env $env
          get_env $env


          # Wait a bit for HTML UI to load?
          curl -D - -sf -L -o /dev/null $JENKINS_URL/login || {
            while true
            do
              log "Waiting for HTML UI... ($JENKINS_URL/login)"
              sleep 15
              curl -D - -sf -L -o /dev/null $JENKINS_URL/login \
                && break
            done
          }
        }


        # Add initial jenkins credential to contact CLI, replace in update.sh
        # using cli grooby.

        #export JENKINS_URL
        ssh_credentials_id="$(hostname -s)-docker-ssh-key"
        #echo ssh_credentials_id=$ssh_credentials_id

        log "Creating ~/.ssh/ credentials ID"
        ./script/sh/create-jenkins-ssh-host-credentials.sh \
            jenkins "$(hostname) Docker SSH Key" $ssh_credentials_id

      } || noop
    ;;

esac


