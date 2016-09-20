#!/usr/bin/env bash

# Helper to setup:
# - Jenkins Job Builder [JJB]
# - Jenkins CLI client.

# Id: docker-jenkins/0.0.2 init.sh

test -n "$hostname" || hostname=$(hostname)

. $(dirname $0)/util.sh
scriptname=/opt/dotmpe/docker-jenkins/init

SRC_PREFIX=/src/

# Clone and install JJB
try_install_jjb()
{
  test -n "$JJB_HOME" || JJB_HOME=$SRC_PREFIX/jenkins-job-builder
  install_jjb
}

jjb_home()
{
  test -n "$JJB_HOME" || JJB_HOME=$SRC_PREFIX/jenkins-job-builder
  echo $JJB_HOME
}

install_jjb()
{
  log "Installing JJB and templates.."

  test -e "$JJB_HOME" || {
    mkdir -vp $(dirname $JJB_HOME) || err "Failed to created basedir for $JJB_HOME" 1

    git clone https://github.com/dotmpe/jenkins-job-builder.git $JJB_HOME \
      || err "Error cloning to $JJB_HOME" 1
  }

  log "Installing JJB.."
  pushd $JJB_HOME
  python setup.py -q install \
    && log "JJB install complete" \
    || err "Error during JJB installation" 1
  popd

  jenkins-jobs --version && {
    log "JJB install OK"
  } || {
    err "JJB installation invalid" 1
  }
}

try_install_jtb()
{
  test -n "$JTB_HOME" || JTB_HOME=$SRC_PREFIX/jenkins-templated-builds
  install_jtb "$@"
}

jtb_home()
{
  test -n "$JTB_HOME" || JTB_HOME=$SRC_PREFIX/jenkins-templated-builds
  echo $JTB_HOME
}

install_jtb()
{
  test -n "$JTB_HOME" || return 1
  test -e "$JTB_HOME" || {
    mkdir -vp $(dirname $JTB_HOME) \
      || err "Failed to created basedir for $JTB_HOME" 1
    git clone https://github.com/dotmpe/jenkins-templated-builds.git $JTB_HOME
  }
  case "$1" in
    latest|*-latest|latest-*|*-latest-* )
      cd $JTB_HOME
      ( git checkout master && git pull && make build ) || return $?
      ;;
    * )
      cd $JTB_HOME
      ( git checkout $1 && git pull && make build ) || return $?
      ;;
  esac
}

# Configure JJB
init_jjb()
{
  cat <<HERE

[job_builder]
allow_empty_variables=True
ignore_cache=True
keep_descriptions=True
include_path=.:/opt/jtb/tpl
include=*.yaml
recursive=True
allow_duplicates=False
exclude=.travis.*:build:manual:vendors

[jenkins]
user=$3
password=$2
url=http://$1/
query_plugins_info=False

HERE
}

# Initialize script to use as shortcut to jenkins-cli.jar
init_cli()
{
  prerun=
  test -n "$1" \
    && jar_f="$1" \
    || {

      prerun='pk=$(echo $HOME/.ssh/id_?sa | cut -f 1 -d " ")
        test -n "$pk" -a -e "$pk" || {
          echo "No keyfile for CLI: $pk"; exit 1; }'

      jar_f="-s http://localhost:8080 -i \$pk"
    }

  test -n "$2" \
    && cmd_f="$2" # For --username/--pasword...

  { cat <<HERE
#!/bin/sh
$prerun
cd \$JENKINS_HOME/
java -jar war/WEB-INF/jenkins-cli.jar $jar_f "\$@" $cmd_f || exit \$?
HERE
  } || return $?
}

init_cb_folder()
{
  test -n "$1" || err "init_cb_folder: name-id argument expected" 1
  test -n "$2" || err "init_cb_folder: display-name argument expected" 1
  test -z "$4" || err "surplus arguments: '$1'" 1
  { cat <<EOM
<?xml version='1.0' encoding='UTF-8'?>
<com.cloudbees.hudson.plugins.folder.Folder plugin="cloudbees-folder@5.10">
  <properties/>
  <description>$3</description>
  <displayName>$2</displayName>
  <views>
    <hudson.model.AllView>
      <owner class="com.cloudbees.hudson.plugins.folder.Folder" reference="../../.."/>
      <name>All</name>
      <filterExecutors>false</filterExecutors>
      <filterQueue>false</filterQueue>
      <properties class="hudson.model.View\$PropertyList"/>
    </hudson.model.AllView>
  </views>
  <viewsTabBar class="hudson.views.DefaultViewsTabBar"/>
  <healthMetrics>
    <com.cloudbees.hudson.plugins.folder.health.WorstChildHealthMetric/>
  </healthMetrics>
  <icon class="com.cloudbees.hudson.plugins.folder.icons.StockFolderIcon"/>
</com.cloudbees.hudson.plugins.folder.Folder>
EOM
  } > /tmp/create-item-cb-folder.xml

  r=
  ( /usr/local/bin/jenkins-cli \
    create-job $1 || r=$? ) < /tmp/create-item-cb-folder.xml

  rm /tmp/create-item-cb-folder.xml

  test -z "$r" || {
    err "Error creating folder '$1' (name: $2), error code: $r"
    exit $r
  }
}


try_install_juc()
{
  test -n "$JUC_HOME" || JUC_HOME=/src/jenkins-userContent
  install_juc
}

install_juc()
{
  test -n "$JUC_HOME" || return 1
  test -e "$JUC_HOME" || {
    mkdir -vp $(dirname $JUC_HOME) || err "Failed to created basedir for $JUC_HOME" 1
    git clone https://github.com/dotmpe/jenkins-userContent.git $JUC_HOME
  }
}


# Run over all installed plugins with updates
update_plugins()
{
  updates=$(jenkins-cli list-plugins \
    | grep -e ')$' \
    | awk '{ print $1 }')
  sleep 2
  test -n "$updates" && {
    log "Updating plugins: $(echo $updates)"
    jenkins-cli install-plugin $updates && {
      sleep 2
      jenkins-cli safe-restart
    }
    sleep 2
  } || {
    log "Plugins are up to date"
    sleep 1
  }
}

wait_for_jenkins()
{
  wait_for_jenkins_ps || return $?
  wait_for_startup || return $?
}

wait_for_jenkins_ps()
{
  test -n "$1" && sleep=$1 || sleep=5
  while true
  do
    ps aux | grep -v grep | grep -q java.*jar.*jenkins.war >/dev/null && {
      log "Jenkins is running"
      return 0
    } || {
      log "Jenkins not running.. waiting $sleep seconds"
      sleep $sleep
    }
  done
}

wait_for_startup()
{
  test -n "$1" && sleep=$1 || sleep=30
  while true
  do
    #jenkins-cli version 2> /dev/null && {
    #}
    version=$(jenkins-cli version 2>/dev/null)
    test -z "$version" || {
      log "Jenkins CLI online"
      return
    }
    log "Waiting for CLI..."
    sleep $sleep
  done
}

customize()
{
  cd $JENKINS_HOME
  for x in title.png headshot.png
  do
    test -e custom/$x && {
      mkdir -vp war/images/
      cp custom/$x war/images/
      log "Customized war/images/$x"
    }
  done
}

init_node()
{
  test -n "$1" || err "expected node XML config path name" 1
  test -e "$1" || err "no such node XML config path: '$1'" 1
  test -n "$2" || set -- "$1" "$(basename $1 .xml)"
  test -z "$3" || err "surplus arguments '$3'" 1
  jenkins-cli create-node < $1 || {
    sleep 2
    err "Create '$2' failed, trying update"
    jenkins-cli update-node $2 < $1 \
      || err "Failed adding node $2" 1
  }
  sleep 1
}

generate_node()
{
  local name=$1 file=$2 ; shift 2
  test -n "$file" || file="/tmp/jenkins-nodes/$name.xml"
  test -n "$name" -a -n "$file"
  test ! -e "$file" || err "Node config file already exists: $file" 1
  mkdir -vp $(dirname "$file")

  test -z "$(echo $@)" || {
    declare "$@"
  }

  { cat <<EOM
<?xml version="1.0" encoding="UTF-8"?>
<slave>
  <name>$name</name>
  <description>$DESCRIPTION</description>
  <remoteFS>$FS</remoteFS>
  <numExecutors>$EXECUTORS</numExecutors>
  <mode>$MODE</mode>
  <retentionStrategy class="hudson.slaves.RetentionStrategy$Always"/>
  <launcher class="hudson.plugins.sshslaves.SSHLauncher" plugin="ssh-slaves@1.11">
    <host>$HOST</host>
    <port>$PORT</port>
    <credentialsId>$CREDENTIALS_ID</credentialsId>
    <maxNumRetries>0</maxNumRetries>
    <retryWaitTime>0</retryWaitTime>
  </launcher>
  <label>$LABEL</label>
  <nodeProperties/>
  <userId>$USER</userId>
</slave>
EOM
  } > $file
}

# (re)set list view by name (unused, using cURL with API instead)
init_view()
{
  cd $JENKINS_HOME
  jenkins-cli create-view < $JENKINS_HOME/custom/views/$1.xml || {
    sleep 2
    err "Create '$1' failed, trying update"
    jenkins-cli update-view $1 < $JENKINS_HOME/custom/views/$1.xml \
      || err "Failed adding custom view $1"
  }
  log "Initialized view '$1'"
  sleep 1
}

init_jtb_preset()
{
  test -n "$JTB_HOME" || err "Need JTB_HOME" 1
  echo JTB_HOME=$JTB_HOME
  cd $JTB_HOME
  test dist -nt tpl || ./bin/jtb.sh build
  local j=$1
  shift
  eval $@ ./bin/jtb.sh compile-preset $j
  log "Generated Job ${j}"
}

reset_login()
{
  test -n "$1" || set -- "jenkins" "jenkins"
  test -n "$2" || set -- "$1" "$1"
  echo \
    'jenkins.model.Jenkins.instance.securityRealm.createAccount("'"$1"'", "'"$2"'")' \
    | jenkins-cli groovy =
}



# Docker entry-point for container process
main()
{
	# if `docker run` first argument start with `--` the user is passing jenkins launcher arguments
	if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then

		eval "exec java $JAVA_OPTS -jar /usr/share/jenkins/jenkins.war $JENKINS_OPTS \"\$@\"" || return $?

	else

		# If first argument corresponds to a local function name, run that
		local func=$(echo "$1" | tr '-' '_')
		test -n "$func" && type $func 2>&1 1> /dev/null && {
			shift 1
			$func "$@" || return $?
		} || {

			# As argument is not arguments to jenkins or a local function, assume user want to run his own process, for sample a `bash` shell to explore this image
			exec "$@" || return $?

		}

	fi
}

set -e

main "$@"

