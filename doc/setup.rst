
Instructions for 0.0.3::

- Install dotmpe/jenkins-job-builder (f_ci_pipeline branch)::

    sudo python setup.py install

- Prepare jenkins-templated-builds checkout::

    pd enable jenkins-templated-builds
    cd jenkins-templated-builds
    make dist

- Prepare jenkins-userContent checkout::

    pd enable jenkins-userContent

- Build jenkins-slave-treebox on ubuntu:14.04 (from branch f_ci_pipeline)::

    cd ~/project
    pd enable docker-treebox
    cd docker-treebox
    git checkout f_ci_pipeline
    Tag_Latest=1 \
    ./build.sh 14.04

  This builds some images with SSH login ``treebox:treebox``.

- Start automated Jenkins 2.0 setup::

    ./inits.sh - prod 2.0

  During build the jenkins user, API user, and API key should be asked.
  Only value 'jenkins' is supported, the password is the same. The key is
  generated and available after logging in, in the jenkins configuration view.

  The local SSH user keys are duplicated to the container, and used for
  accessing Jenkins CLI and slaves, etc.

  Scripts:

  - Only inits.sh is supported and expected to work without further arguments.
    But build.sh, run.sh, config.sh, update.sh should be runnable separately
    without minimal additional args/env. Generic syntax::

      cname=<container-name> ./(build|run|config|update).sh <env> <tag>

  - vars.sh should contain all settings (but is getting spread around a bit, to
    env.sh, inits.sh).

  Config files:

  - plugins.txt is recompiled each build to find new dependencies.
    The latest plugins are build into the container.
  - all XML files in custom/views/ are used to create views.
  - credentials.json contains the initial Jenkins credentials.
  - clouds.json contains the initial Docker cloud configuration and slave
    template images.
  - projects.tab contains the various types of jobs and different ways to enter
    them into Jenkins.
  - build-triggers.tab lists various jobs to trigger at the end of init.

Lots of prerequisites not documented, or tested at this tag.
For failing jobs, first check GIT credentials.

