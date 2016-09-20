#!/bin/bash

set -e


scriptname=$(basename $0)
test -n "$tag" || . ./vars.sh "$@"

test -n "$NAME" || err "NAME env expected" 1

test -n "$JENKINS_URL" || {
  echo "No JENKINS_URL env"
  exit 1
}


test -n "$ID" || ID="$(echo "$NAME" | sed 's/[^A-Za-z0-9_\/-]/-/g')"
test -n "$DISPLAY_NAME" || DISPLAY_NAME="$(basename "$NAME")"


base=
dirname="$(dirname "$ID")"
test -z "$dirname" -o "$dirname" = "." && {
  parent_base=
  base="job/$ID/"
} || {
  P="$ID"
  while test "$P" != "."
  do
    base="job/$(basename "$P")/$base"
    P="$(dirname "$P")"
  done
  test -z "$base" || parent_base="$(dirname "$(dirname "$base")")/"
}



log "Creating CloudBees Job Folder: '$DISPLAY_NAME' ($ID)"
log "at server $JENKINS_URL/$parent_base"

curlflags="-fsL"
#debug_f="-D -"

case "$tag" in

  1.* )

      curl -X post $curlflags \
          -o /tmp/$scriptname-1-$(uuidgen).curlout \
          -d name="$(basename "$ID")" \
          -d mode="com.cloudbees.hudson.plugins.folder.Folder" \
          $JENKINS_URL/${parent_base}createItem \
          || err "Create folder $ID ($DISPLAY_NAME): cURL returned error $?" $?

      log "Job item created, updating display name"


      log "Updating CloudBees Job Folder: '$DISPLAY_NAME' ($ID)"
      log "at server $JENKINS_URL/$base"

      curl -X post $curlflags \
          -o /tmp/$scriptname-2-$(uuidgen).curlout \
          -d json='{ "name": "'$(basename "$ID")'", "displayNameOrNull": "'"$DISPLAY_NAME"'", "description": "", "": ["0", "0"], "viewsTabBar": {"stapler-class": "hudson.views.DefaultViewsTabBar", "$class": "hudson.views.DefaultViewsTabBar"}, "icon": {"stapler-class": "com.cloudbees.hudson.plugins.folder.icons.StockFolderIcon", "$class": "com.cloudbees.hudson.plugins.folder.icons.StockFolderIcon"}, "healthMetrics": {"stapler-class": "com.cloudbees.hudson.plugins.folder.health.WorstChildHealthMetric", "$class": "com.cloudbees.hudson.plugins.folder.health.WorstChildHealthMetric"}, "com-cloudbees-hudson-plugins-folder-properties-FolderCredentialsProvider$FolderCredentialsProperty": {"domainCredentials": {"domain": {"name": "", "description": ""}}}, "core:apply": ""} ' \
          "$JENKINS_URL/${base}configSubmit" \
            || err "Updated folder $ID ($DISPLAY_NAME): cURL returned error $?" $?

      log "Job Folder $ID ready at <$JENKINS_URL/job/$ID>"

    ;;

  2.* )

      # Note: 2.0 gets auth setup, maybe can get a login. Or seem to need a
      # Jenkins-Crumb value perhaps to post.
      # Also, stdin is not working on the docker-exec jenkins-cli bridge.
      # So moved script into container.

      docker exec $cname \
        /opt/dotmpe/docker-jenkins/init.sh init_cb_folder "$ID" \
          "$DISPLAY_NAME" "$DESCRIPTION" \
          || exit $?

    ;;

esac
