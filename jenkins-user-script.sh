
set -e

scriptname="$(basename "$0")"
type err >/dev/null 2>&1 || { . ./util.sh; }

cmd="$1"
shift


info "'$@'"


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
    test -n "$cname" || error "cname env expected" 13
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
    test -n "$cname" || error "cname env expected" 13
    echo 'jenkins.model.Jenkins.instance.securityRealm.createAccount("jenkins", "jenkins")' \
      | docker exec -i $cname jenkins-cli groovy = \
        || exit $? ;;

  jtb_revision )
    $0 docker-exec \
      'test -n "$JTB_SRC_DIR" && test -e "$JTB_SRC_DIR" && cd $JTB_SRC_DIR && git show-ref && git status ; exit' \
        || exit $? ;;

  compile_jtb_preset )
    $0 docker-exec \
      'cd $JTB_SRC_DIR; mkdir -vp dist; test dist -nt tpl || ./jtb-process.sh tpl dist ;'\
      './bin/jtb.sh compile-preset '$1 \
        || exit $? ;;

  reconfigure_jtb_job )
    test -n "$1" || exit 209
    $0 docker-exec \
      'test -e "'$1'" && cd $JTB_SRC_DIR && jenkins-jobs update '"$1"':$JTB_SRC_DIR/dist/base.yaml || { echo "Missing '$1'"; exit 1; }' \
        || exit $? ;;

  reconfigure_jtb_preset )
    $0 reconfigure_jtb_job '$JTB_SRC_DIR/preset/'"$1"'.yaml' \
        || exit $? ;;

  reconfigure_jtb_update_existing_projects )
    $0 reconfigure_jtb_job '$JTB_SRC_DIR/example/update-existing-projects.yaml' \
        || exit $? ;;

  reconfigure_juc )

    # Install, update
    #$0 docker-exec-ti \
    #  /opt/dotmpe/docker-jenkins/init.sh try_install_juc \
    #    || exit 2$?
    dckr_user=root $0 docker-exec-ti-user \
      'test -n "$JNK_UC_SRC" -a -e "$JNK_UC_SRC" || { echo "JNK_UC_SRC error" 1>&2; exit 99; } && cd $JNK_UC_SRC && git checkout master && git pull' \
        || exit 3$?

    # Reconfigure non-JTB travis job
    #$0 reconfigure_jtb_job '$JNK_UC_SRC/jenkins-ci.yaml' \
    #    || exit 4$?

    # Prepare / reconfigure JTB preset for JUC
    #$0 docker-exec-ti \
    #    /opt/dotmpe/docker-jenkins/init.sh init_jtb_preset gh-juc \
    #    || exit 5$?
    #$0 compile_jtb_preset 'gh-juc' \
    #    || exit 6$?
    $0 reconfigure_jtb_job '$JTB_SRC_DIR/gh-juc.yaml' \
        || exit 6$?

    ;;

  * )
      error "No sub-command '$cmd'" 14
    ;;

esac

