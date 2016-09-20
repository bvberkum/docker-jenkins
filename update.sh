#!/bin/sh

set -e

scriptname=update
test -n "$tag" || . ./vars.sh "$@"
#test -n "$api_user" || get_env

type err >/dev/null 2>&1 || { . ./util.sh; }


log "Updates"

case "$image_type" in

  jenkins-server* )


      trueish "$Update_Plugins" && {

        # Upgrade plugins once jenkins is online, and restart again
        log "Updating plugins..."
        ./jenkins-user-script.sh dotmpe-init wait_for_jenkins
        ./jenkins-user-script.sh dotmpe-init update_plugins
        ./jenkins-user-script.sh dotmpe-init wait_for_jenkins
      }

      trueish "$Update_Customizations" && {

        # Customize header logo+title
        log "Customizing..."
        docker exec -ti $cname \
            /opt/dotmpe/docker-jenkins/init.sh customize
      }


      trueish "$Update_Packages" && {

        log "Adding more packages"
        docker exec -u root -ti $cname npm install -g grunt-cli stylus recess
      }


      trueish "$Update_Credentials" && {

        log "Updating credentials"

        docker cp credentials.json \
          $cname:/opt/dotmpe/docker-jenkins/credentials.json

        update_cred_retries=8
        while test $update_cred_retries -gt 0
        do
          env=$env tag=$tag cname=$cname \
          ./update-cli-groovy.sh  configure-credentials \
              Update_Credentials_Clear=$Update_Credentials_Clear \
              Build_Credentials_Json_File="'/opt/dotmpe/docker-jenkins/credentials.json'" \
          && {
            log "Credentials succesfully updated"
            break;
          } || {
            update_cred_retries=$(( $update_cred_retries - 1 ))
            log "Credentials groovy script failed, retries: $update_cred_retries"
            sleep 30
          }
        done

        docker exec $cname rm /opt/dotmpe/docker-jenkins/credentials.json
      }


      grep -q '^docker-plugin$' plugins.txt || Update_Clouds=0

      trueish "$Update_Clouds" && {

        # Cloud configuration

        sed 's/\-dev\>/-'$env'/g' clouds.json > clouds-$env.json
        docker cp clouds-$env.json \
          $cname:/opt/dotmpe/docker-jenkins/docker-cloud.json
        rm clouds-$env.json

        test -n "$DOCKER_URL" || err "DOCKER_URL missing" 1

        env=$env tag=$tag cname=$cname \
        ./update-cli-groovy.sh  configure-docker-cloud  \
            Update_Cloud_Name="'$(hostname) Docker Machine'" \
            Update_Cloud_Clear=$Update_Cloud_Clear \
            Build_Docker_Cloud_Json_File="'/opt/dotmpe/docker-jenkins/docker-cloud.json'" \
            Swarm_Master_URL="'$DOCKER_URL'"

        docker exec $cname rm /opt/dotmpe/docker-jenkins/docker-cloud.json
      }


      trueish "$Update_Nodes" && {

        . ./script/sh/create-jenkins-nodes.sh

        log "Adding node"
        test -n "$DOTMPE_SLAVE_PORT" -a -n "$DOTMPE_SLAVE_HOST" || {
          err "Missing env vars ($DOTMPE_SLAVE_HOST:$DOTMPE_SLAVE_PORT)" 1
        }
        #log "Adding/updating nodes (slaves.tab)"
        #update_nodes_from_table slaves.tab

        nodeid=${hostname}-jenkins-slave-dotmpe-$env
        generate_node $nodeid \
            DESCRIPTION='Ubuntu 14.04.4 LTS, Trusty Tahr' \
            FS='/home/jenkins' EXECUTORS=1 MODE='EXCLUSIVE' \
            HOST="$DOTMPE_SLAVE_HOST" PORT="$DOTMPE_SLAVE_PORT" \
            CREDENTIALS_ID='jenkins-ssh-slave-passwd-credentials' \
            LABEL='ubuntu trusty debian' USER='jenkins'  \
            && log "Added node $nodeid" \
            || err "Error adding node $nodeid"

        nodeid=${hostname}-jenkins-slave-dotmpe-dind-$env
        generate_node $nodeid \
            DESCRIPTION='Ubuntu 14.04.4 LTS, Trusty Tahr' \
            FS='/home/jenkins' EXECUTORS=1 MODE='EXCLUSIVE' \
            HOST="$DOTMPE_SLAVE_HOST" PORT="$DOTMPE_DIND_SLAVE_PORT" \
            CREDENTIALS_ID='jenkins-ssh-slave-passwd-credentials' \
            LABEL='ubuntu trusty debian dind' USER='jenkins'  \
            && log "Added node $nodeid" \
            || err "Error adding node $nodeid"

      }


      trueish "$Update_Projects" && {

        # FIXME: jenkins:jenkins config gets created during build.
        # Get existing JJB config from container, replacing URL with external
        jjb_config=.jenkins-jobs-${env}.ini
        docker cp $cname:/etc/jenkins_jobs/jenkins_jobs.ini $jjb_config.tmp
        cat $jjb_config.tmp | grep -v '^url=' > $jjb_config
        echo "url=$JENKINS_URL" >> $jjb_config
        rm $jjb_config.tmp
        export jjb_config


        # Use JTB in container to setup some jobs
        test -n "$Build_Offline" \
          && docker exec -ti $cname bash -c 'cd $JTB_HOME/ && git checkout dev' \
          || docker exec -ti $cname bash -c 'cd $JTB_HOME/ && git checkout dev && git pull origin dev'

        . ./script/sh/create-jenkins-jobs.sh

        log "Updating jobs (projects.tab)"
        generate_jobs_from_tab projects.tab

        # TODO cleanup old JJB/JTB scripts
        #export cname
        #./jenkins-user-script.sh reconfigure_jtb_update_existing_projects
      }


      trueish "$Update_Views" && {

        # Create some practical views
        log "Updating views..."

        # XXX: see CLI init below, test again
        #log "Moving fresh cutom/views into container"
        #docker exec -ti $cname rm -rf $chome/custom/views || printf ""
        #docker cp custom/views/ $cname:$chome/custom/views
        #log "Copy OK"

        for p in custom/views/*.xml
        do

          name=$(basename $p .xml)
          case "$name" in
            Cat )
                grep -q categorized-view plugins.txt || continue
              ;;
            ls )
                grep -q extra-columns plugins.txt || continue
              ;;
          esac

          log "Creating custom view '$name'"

          ./script/sh/create-jenkins-view.sh $p || {
            err "Error creating '$name' ($p)"
          }

          #docker exec -ti $cname jenkins-cli delete-view $name 2>/dev/null || printf ""
          #docker exec -ti $cname \
          #    /opt/dotmpe/docker-jenkins/init.sh init_view $name

        done
      }


      trueish "$Build_Triggers" && {

        log "Triggering builds (build-triggers.tab)"
        . ./script/sh/trigger-jenkins-job.sh
        trigger_builds_from_table build-triggers.tab

      } || noop

    ;;
esac


