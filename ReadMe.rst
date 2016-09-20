:Created: 2015-08-30
:Updated: 2016-06-06
:Version: 0.0.2

Jenkins Server
  - `bvberkum/jenkins-server <//hub.docker.com/r/bvberkum/jenkins-server>`_

    .. image:: https://badge.imagelayers.io/bvberkum/docker-jenkins:latest.svg
        :target: https://imagelayers.io/?images=bvberkum/docker-jenkins:latest
        :alt: Get your own badge on imagelayers.io



Features
  - Customized Jenkins docker has CLI and JJB pre-installed::

      docker exec -ti $cname jenkins-cli help
      docker exec -ti $cname jenkins-jobs help

  - Use JJB templates and initialize Jenkins jobs from YAML::

      jenkins-jobs update my-build.yaml

  - Build job configurations from JJB templates from dotmpe/jenkins-templated-builds.
    Use presets values with templates, or fill out placeholders using
    generate, and write new YAML formatted jobs::

      cd $JTB_HOME
      ./bin/jtb.sh compile-preset gh-jtb
      jenkins-jobs update gh-jtb.yaml:tpl/base.yaml

    Or use generate custom jobs based on templates directly from environment vars in shell scripts::

      name=jtb job-template-builder.py generate <tpl-id> <tpl-files> > my-build.yaml

    And trigger the build::

      docker exec -ti $cname jenkins-cli build <job-id>


Build, start, and configure::

  ./build.sh && \
  ./run.sh && \
  ./config.sh

The main script is ``init.sh``. That and other scripts above take arguments
``[env [tag]]`` (default ``dev latest``).

Refer to those scripts for functionality. Documentation is not mantained and
can easily be out of date. Script `inits.sh`` has a few pre-configurations.

Dev
----
Branches
  f_ci_pipeline
    Main dev.
  f_vartabs
    Draft vars.tab

Issues
  - Seems there is no CLI command to remove/clean plugins.
    Probably a matter of emptying the directory and reloading.
  - CLI works except with stdin. Taking the JAR out the container does not help.
    Made one built-in function (init_cb_folder) to generate new folders.

Wishlist
  - Want to initialize title, preferably from fontfile and svg or someting.
    Right now copies custom/title.png and custom/headshot.png.

  - Misc. initial settings now done by hand:

    - turn of HTML description filtering in security settings
    - Add public key to user
    - Get API key from user (for JJB)
    - add docker cloud settings.
      see script/configure-docker-cloud.groovy, possibly.

    - set admin email
    - setup for (docker) slaves
    - added better list view, need to set as default
    - some global choice parameters
    - add console output parsing rules

    - may also try 'jvm_options' = '-Djenkins.install.runSetupWizard=false'
      for manual 2.0 setup.

    - Can use cURL for some provisioning:
      https://gist.github.com/stuart-warren/7786892


.. raw:: html

    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.4.0/css/font-awesome.min.css">
    <link rel="stylesheet" href="https://rawgit.com/wesbos/Font-Awesome-Docker-Icon/master/fontcustom/fontcustom.css">

    <i class="fa fa-docker"></i>


.. image:: docker-logo.png

.. image:: jenkins-logo.png



