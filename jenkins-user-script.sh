
set -e

scriptname="$(basename "$0")"
type err >/dev/null 2>&1 || { . ./util.sh; }

cmd="$1"
shift


log "'$@'"


case "$cmd" in

  git-versioning-install )
    $0 docker-exec-ti \
      'test -x "$(which git-versioning)" || ( mkdir -vp $HOME/build && git clone https://github.com/dotmpe/git-versioning.git $HOME/build/ && cd $HOME/build/git-versioning && make install )' \
      || exit $? ;;

  git-versioning-upgrade )
    $0 docker-exec-ti \
      'cd $HOME/build/git-versioning && git checkout master && git pull && make uninstall && make install' \
      || exit $? ;;

  dotmpe-init )
    $0 docker-exec \
      "/opt/dotmpe/docker-jenkins/init.sh $@" \
      || exit $? ;;

  export-plugins-txt )
    $0 docker-exec \
      "jenkins-cli list-plugins | awk '{print \$1}' | sort" \
      || exit $? ;;

  docker-exec )
    test -n "$dckr_exec_f" || dckr_exec_f="-t"
    test -n "$cname" || err "cname env expected" 13
    docker exec $dckr_exec_f $cname \
      bash -c "export PATH=\$HOME/bin:\$PATH PYTHONPATH=\$HOME/lib/py:\$PYTHONPATH; $@" \
        || exit $? ;;

  docker-exec-ti )
    test -n "$dckr_exec_f" || export dckr_exec_f="-ti"
    $0 docker-exec "$@" || exit $? ;;

  docker-exec-ti-user )
    test -n "$dckr_exec_f" || export dckr_exec_f="-ti -u $dckr_user"
    $0 docker-exec "whoami; $@" || exit $? ;;

  reset-login )
    #echo 'hpsr=new hudson.security.HudsonPrivateSecurityRealm(false); hpsr.createAccount("dummyuser", "dummypassword")' \
    test -n "$cname" || err "cname env expected" 13
    echo 'jenkins.model.Jenkins.instance.securityRealm.createAccount("jenkins", "jenkins")' \
      | docker exec -i $cname jenkins-cli groovy = \
        || exit $? ;;

  jtb_revision )
    $0 docker-exec \
      'test -n "$JTB_HOME" && test -e "$JTB_HOME" && cd $JTB_HOME && git show-ref && git status ; exit' \
        || exit $? ;;

  compile_jtb_preset )
    $0 docker-exec \
      'cd $JTB_HOME; mkdir -vp dist; test dist -nt tpl || ./jtb-process.sh tpl dist ;'\
      './bin/jtb.sh compile-preset '$1 \
        || exit $? ;;

  reconfigure_jtb_job )
    test -n "$1" || exit 209
    $0 docker-exec \
      'cd $JTB_HOME && jenkins-jobs update '"$1"':$JTB_HOME/dist/base.yaml' \
        || exit $? ;;

  reconfigure_jtb_preset )
    $0 reconfigure_jtb_job '$JTB_HOME/preset/'"$1"'.yaml' \
        || exit $? ;;

  reconfigure_jtb_update_existing_projects )
    $0 reconfigure_jtb_job '$JTB_HOME/example/update-existing-projects.yaml' \
        || exit $? ;;

  reconfigure_juc )

    # Install, update
    #$0 docker-exec-ti \
    #  /opt/dotmpe/docker-jenkins/init.sh try_install_juc \
    #    || exit 2$?
    dckr_user=root $0 docker-exec-ti-user \
      'cd /src/jenkins-userContent && git checkout master && git pull' \
        || exit 3$?

    # Reconfigure non-JTB travis job
    #$0 reconfigure_jtb_job '$JUC_HOME/jenkins-ci.yaml' \
    #    || exit 4$?

    # Prepare / reconfigure JTB preset for JUC
    #$0 docker-exec-ti \
    #    /opt/dotmpe/docker-jenkins/init.sh init_jtb_preset gh-juc \
    #    || exit 5$?
    #$0 compile_jtb_preset 'gh-juc' \
    #    || exit 6$?
    $0 reconfigure_jtb_job '$JTB_HOME/gh-juc.yaml' \
        || exit 6$?

    ;;

  * )
      err "No sub-command '$cmd'" 14
    ;;

esac

