#!/bin/sh

jsonp=jenkins-plugins.jsonp
json=jenkins-plugins.json
pretty=jenkins-plugins.yaml

test -s $jsonp \
  || wget http://updates.jenkins-ci.org/update-center.json -O $jsonp

# document should be 3 lines, or 2 line separators and no trailing line-end
lines=$(wc -l $jsonp | awk '{print $1}')
test "$lines" = "2" || {
  echo "Unexpected lines in JSON: $lines"
  exit 1
}

test $jsonp -ot $json \
  || tail -n +2 $jsonp | head -n 1 > $json

test $json -ot $pretty \
  || jsotk.py dump -O yaml --pretty $json > $pretty


list_all_plugins()
{

# TODO: Start daemon and export env
#pwdid=$(pwd | sed 's/[^A-Za-z\.]/-/g')
#export JSOTK_SOCKET=/tmp/${pwdid}-plugins.socket
#jsotk -b $plugins

  jsotk.py $plugins keys \
    -O lines   $json   plugins   | while read plugin
    do
      echo "$(
        jsotk.py path   $json   plugins/$plugin/name
      ) $(
        jsotk.py path   $json   plugins/$plugin/version
      ) $(
        jsotk.py path   $json   plugins/$plugin/dependencies
      )"
    done

}

get_plugin_deps()
{
  jsotk.py objectpath jenkins-plugins.json -O py \
    '$.plugins."'"$1"'".dependencies.*[@.optional is False].name'
}

get_plugin_depspecs()
{
  # FIXME: cannot cat at listed deps properly; how to concat name+version,
  # filter by optional=True
  jsotk.py objectpath jenkins-plugins.json -O py \
    '$.plugins."'"$1"'".dependencies.*[name]' | while read plugin
  do
    echo "$plugin $(
      jsotk.py objectpath jenkins-plugins.json -O py \
        '$.plugins."'"$1"'".dependencies."'"$plugin"'"[version]'
    )"
  done
  #jsotk.py   -O py  objectpath  $json  'plugins/$1/dependencies'
}

get_plugins()
{
  jsotk.py keys -O lines    $json   plugins
}


show_plugins_metadata()
{
  jsotk.py   -O yaml --pretty   path  $json  plugins
}

list_deps()
{
  cat - | sort -du | while read plugin
  do
    plugins="$(get_plugin_deps "$plugin" || return 1)"
    test "$plugins" != "" || continue
    test "$plugins" != "None" || continue
    for plugin in $plugins
    do
      echo $plugin
    done
  done
}

recompile_plugins()
{
  test -n "$1" || set -- plugins.txt
  test -n "$2" || set -- "$1" /tmp/$1
  test ! -e $2 || rm $2
  test -z "$3" || { echo "Surplus arguments: '$3'"; exit 1; }

  cp $1 $2
  # FIXME: tried to filter on plugins+version too, but not working yet?
  #cat $2 | sed -E 's/^([^:]+).*/\^\1\.\*/g' > $2.match
  cp $1 $2.cur

  while test -s "$2.cur"
  do
    echo "Fetch deps for $(wc -l $2.cur | awk '{print $1}') plugins"
    cat $2.cur | list_deps | grep -vFf $2 | sort -du > $2.new
    test ! -s $2.tmp || {
      # FIXME: jsotk objectpython depends on pytz, and has a dirty warning on
      # stdout about it
      grep -vq '^are$' $2.tmp || {
        echo "Please install pytz: pip install pytz"
        exit 1
      }
    }
    test -s $2.new && {
      echo "Adding $(wc -l $2.new | awk '{print $1}') new dependencies"
      cat $2.new >> $2
      #cat $2.new | sed -E 's/^([^:]+).*/\^\1\.\*/g' >> $2.match
      mv $2.new $2.cur
    } || {
      echo "No new deps"
      rm $2.*
    }
  done

  sort -du $2 > $1
  rm $2
}

resort_plugins()
{
  test -n "$1" || set -- plugins.txt
  test -n "$2" || set -- "$1" /tmp/$1
  test ! -e $2 || rm $2
  test -z "$3" || { echo "Surplus arguments: '$3'"; exit 1; }

  mv $1 $2
  sort -du $2 > $1
  rm $2
}

update_std_pluginlist()
{
  resort_plugins plugins_default.txt
  echo "Re-sorted plugins_default.txt"
  cp plugins_default.txt plugins.txt
  recompile_plugins plugins.txt

  wc -l plugins*txt

  #recompile_plugins plugins2.txt
  #recompile_plugins plugins3.txt
}


test "$(basename $0 .sh)" = "get-jenkins-plugins" -a -n "$1" && {

  "$@"

} || printf ""
