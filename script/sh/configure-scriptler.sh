#!/bin/sh
set -e

test -n "$api_user" || get_env


test -e "$1" || exit 199

scriptname=$(basename $1)


configure_http_scriptler()
{

# XXX: could again not get to work with HTML UI, not able to update script once
# created to include Parameters

echo "Removing existing"
curl -LsfS \
  -XGET -o /dev/null \
  --user $api_user:$api_secret \
  -d id="$scriptname" \
  $JENKINS_URL/scriptler/removeScript?id=$scriptname || printf ""



echo "Uploading script"
curl -sfS \
  -XPOST -o /dev/null \
  -vvv \
  --user $api_user:$api_secret \
  -F file=@$1 \
  -F json='{"nonAdministerUsing": false}' \
  $JENKINS_URL/scriptler/uploadScript



echo "Updating with params"
{
printf -- '{ "id": "'$scriptname'", "scriptname": "'$scriptname'", "comment": "'$scriptname'", "nonAdministerUsing": false, "onlyMaster": false, "defineParams": { "parameters": { "name": "Config_Clouds_Clear", "value": "0" }}, "script": "'

cat $1 | perl -pe 's/\n/\\n/g' | sed -e 's/\"/\\"/g' | tr -d '\n'
printf -- '", "": "'
cat $1 | perl -pe 's/\n/\\n/g' | sed -e 's/\"/\\"/g' | tr -d '\n'
printf '"}'

} > script.json

# opts for application/x-www-form-urlencoded
curl -sfS \
  -XPOST -o /dev/null \
  -vvv \
  --user $api_user:$api_secret \
  -F "id=$scriptname" \
  -F "scriptname=$scriptname" \
  -F "comment=$scriptname" \
  -F "defineParams=on" \
  -F "script=@$1" \
  -F "json=@script.json" \
  $JENKINS_URL/scriptler/scriptAdd?id=$scriptname

rm script.json



echo "Executing"
curl -sfS \
  -XPOST -o /dev/null \
  --user $api_user:$api_secret \
  $JENKINS_URL/scriptler/run/$scriptname?Config_Clouds_Clear=1

}

