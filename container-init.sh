#!/usr/bin/env bash

# Helper to setup:
# - Jenkins Job Builder [JJB]
# - Jenkins CLI client.

# Id: docker-jenkins/0.0.4-dev container-init.sh

test -n "$hostname" || hostname=$(hostname)

. $(dirname $0)/util.sh

test -e "/srv/project-local" && {
  SRC_PREFIX=/srv/project-local
} || {
  SRC_PREFIX=/src/
}

# Clone and install JJB
try_install_jjb()
{
  test -n "$JJB_SRC_DIR" || JJB_SRC_DIR=$SRC_PREFIX/jenkins-job-builder
  install_jjb "$@"
}

jjb_home()
{
  test -n "$JJB_SRC_DIR" || JJB_SRC_DIR=$SRC_PREFIX/jenkins-job-builder
  echo $JJB_SRC_DIR
}

install_jjb()
{
  info "Installing JJB and templates.."

  test -e "$JJB_SRC_DIR" || {
    mkdir -vp $(dirname $JJB_SRC_DIR) || error "Failed to created basedir for $JJB_SRC_DIR" 1

    git clone https://github.com/dotmpe/jenkins-job-builder.git $JJB_SRC_DIR \
      || error "Error cloning to $JJB_SRC_DIR" 1
  }

  info "Installing JJB.."
  cd $JJB_SRC_DIR
  test -z "$1" || {
    git checkout $1 || error "Cannot checkout $1" 1
  }
  git pull

  pip install -r requirements.txt -e . \
    && info "JJB install complete" \
    || error "Error during JJB installation" 1
  cd

  jenkins-jobs --version && {
    info "JJB install OK"
  } || {
    error "JJB installation invalid" 1
  }
}

try_install_jtb()
{
  test -n "$JTB_SRC_DIR" || JTB_SRC_DIR=$SRC_PREFIX/jenkins-templated-builds
  install_jtb "$@"
}

jtb_home()
{
  test -n "$JTB_SRC_DIR" || JTB_SRC_DIR=$SRC_PREFIX/jenkins-templated-builds
  echo $JTB_SRC_DIR
}

install_jtb()
{
  test -n "$JTB_SRC_DIR" || return 1
  info "Installing Jenkins Templated Builds"

  test -e "$JTB_SRC_DIR" || {
    mkdir -vp $(dirname $JTB_SRC_DIR) \
      || error "Failed to created basedir for $JTB_SRC_DIR" 1
    git clone https://github.com/dotmpe/jenkins-templated-builds.git $JTB_SRC_DIR
  }

  cd $JTB_SRC_DIR
  test -z "$1" || {
    git checkout $1 || error "Cannot checkout $1" 1
  }
  git pull

  make build
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
  test -n "$1" || error "init_cb_folder: name-id argument expected" 1
  test -n "$2" || error "init_cb_folder: display-name argument expected" 1
  test -z "$4" || error "surplus arguments: '$1'" 1
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

  ( /usr/local/bin/jenkins-cli create-job $1 || {
      r=$?
      rm /tmp/create-item-cb-folder.xml
      error "Error creating folder '$1' (name: $2)"
      exit $r
    }
  ) < /tmp/create-item-cb-folder.xml

  rm /tmp/create-item-cb-folder.xml
}


try_install_juc()
{
  test -n "$JNK_UC_SRC" || JNK_UC_SRC=$SRC_PREFIX/jenkins-userContent
  install_juc
}

install_juc()
{
  test -n "$JNK_UC_SRC" || return 1
  test -e "$JNK_UC_SRC" || {
    mkdir -vp $(dirname $JNK_UC_SRC) || error "Failed to created basedir for $JNK_UC_SRC" 1
    git clone https://github.com/dotmpe/jenkins-userContent.git $JNK_UC_SRC
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
    info "Updating plugins: $(echo $updates)"
    jenkins-cli install-plugin $updates && {
      sleep 2
      jenkins-cli safe-restart
    }
    sleep 2
  } || {
    info "Plugins are up to date"
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
      info "Jenkins is running"
      return 0
    } || {
      info "Jenkins not running.. waiting $sleep seconds"
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
      info "Jenkins CLI online"
      return
    }
    info "Waiting for CLI..."
    sleep $sleep
  done
}

customize()
{
  cd $JENKINS_HOME
  for x in custom/*.png
  do
    test -e $x && {
      mkdir -vp war/images/
      cp $x war/images/
      info "Customized war/images/$(basename $x)"
    } || {
      warn "$x" 
    }
  done
}

init_node()
{
  test -n "$1" || error "expected node XML config path name" 1
  test -e "$1" || error "no such node XML config path: '$1'" 1
  test -n "$2" || set -- "$1" "$(basename $1 .xml)"
  test -z "$3" || error "surplus arguments '$3'" 1
  jenkins-cli create-node < $1 || {
    sleep 2
    error "Create '$2' failed, trying update"
    jenkins-cli update-node $2 < $1 \
      || error "Failed adding node $2" 1
  }
  sleep 1
}

generate_node()
{
  local name=$1 file=$2 ; shift 2
  test -n "$file" || file="/tmp/jenkins-nodes/$name.xml"
  test -n "$name" -a -n "$file"
  test ! -e "$file" || error "Node config file already exists: $file" 1
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
    error "Create '$1' failed, trying update"
    jenkins-cli update-view $1 < $JENKINS_HOME/custom/views/$1.xml \
      || error "Failed adding custom view $1"
  }
  info "Initialized view '$1'"
  sleep 1
}

init_jtb_preset()
{
  test -n "$JTB_SRC_DIR" || error "Need JTB_SRC_DIR" 1
  cd $JTB_SRC_DIR
  test dist -nt tpl || ./bin/jtb.sh build
  local j=$1
  shift
  eval $@ ./bin/jtb.sh compile-preset $j
  info "Generated Job ${j}"
}

reset_login()
{
  test -n "$1" || set -- "jenkins" "jenkins"
  test -n "$2" || set -- "$1" "$1"
  echo \
    'jenkins.model.Jenkins.instance.securityRealm.createAccount("'"$1"'", "'"$2"'")' \
    | jenkins-cli groovy =
}

set_default_view()
{
  test -n "$1" || err "View ID expected" 1
  grep -q primaryView $HOME/config.xml && {
    sed -i.bak \
      's#<primaryView>.*</primaryView>#<primaryView>'"$1"'</primaryView>#g' \
      $HOME/config.xml
  } || {
    sed -i.bak \
      's#</hudson>#<primaryView>'"$1"'</primaryView></hudson>#g' \
      $HOME/config.xml
  }
}

add_user_public_key()
{
  test -n "$1" || err "Expected user" 1
  test -n "$2" || err "Expected key" 1

  sed -i.bak 's#<authorizedKeys></authorizedKeys>#<authorizedKeys>'"$2"'</authorizedKeys>#g' \
    $HOME/users/$1/config.xml || return $?
}


# Docker entry-point for container process
main()
{
	scriptname="container-init:$hostname"
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

