#!/bin/sh
# Post-SCM script

scriptname=init

. ./vars.sh "$@"


set -e


cid=$(docker inspect --format="{{.Id}}" $cname || echo "")

trueish "$Build_Destroy_Existing" || {

  trueish "$Build_Only" || {
    # Only one instance per name can exist
    test -z "$cid" \
        || err "Another container named '$cname' exists" 1
  }
}

trueish "$Build_Image" && {

  case "$image_type" in jenkins-server* )

    trueish "$Recompile_Plugins" && {
      . ./script/sh/get-jenkins-plugins.sh

      # Recompile plugin deps
      log "Updating plugins from default list"
      update_std_pluginlist

      # Note: Jobs (JTB etc), Views (custom/views) have plugin deps
      # Views uses the list above.
    }
  ;; esac

  log "Starting build script"
  . ./build.sh || exit $?

  log "Tagging latest $vendor/$image_type (from $image_ref)"
  docker tag $image_ref $vendor/$image_type:latest
}

trueish "$Build_Only" && exit 0


. ./run.sh


test -n "$cid" || exit 2
log "Started container cid=$cid"

trueish "$Build_Config" || exit 0

. ./config.sh



trueish "$Build_Updates" && {

  # Customize, update Views. Regenerate jobs using JJB+JTB
  . ./update.sh || exit $?

}

echo "Container ready, docker ps ($cname):"
docker ps | grep $cname

#echo "Logs:"
#docker logs $cname

echo "IP Address/Ports"
echo \
  $(docker inspect --format '{{ .NetworkSettings.IPAddress }}' $cid) \
  $(docker port $cid)
# $(docker inspect --format='{{range $p, $conf := .NetworkSettings.Ports}} {{$p}} -> {{(index $conf 0).HostPort}} {{end}}' $cid)


echo "Image $image_ref build, and running at $hostname"


# Id: docker-jenkins/0.0.2 init.sh
