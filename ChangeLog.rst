[0.0.2]
  - Automated 2.0 setup with prepared XML views added, slaves, jobs, and
    triggers from tables, credentials and clouds from JSON.

0.0.3
  - Still testing Jenkins 2.0 (2.7 available).
  - Moved from docker-machine to docker 1.11 in Vagrant vbox.
    1.12 is atm. not compatible with docker-jenkins plugin. [#]_
  - Contains cloud setup with three images. Two pre-build, pre-started slaves,
    one which works. Lots of auxiliary and personal jobs are added and
    triggered. Not all work for now, but Jenkins does.
    See also first edition of setup guide.

(0.0.4-dev)
  - Fixed user security setup (broke on wrong comment format).
  - Added preconfigured Simple Theme settings file.
  - Added Ivy plugin to keep exceptions down, and maybe startup time too.
  - Minor updates in verbosity. Added grep for warn/error/exception on docker logs at the end.
  - Misc. other cleaning of build.
  - Added build-description column to custom Test list view.
  - Whishlist review.
  - Set executors to 1, but added JEKNINS_EXECUTORS env var.
  - Fixes for JJB configs (.jjb.yml) for description contain source
    project name and version, and expose version and
    TOTEST: JJB filename to build env.


.. [#] `docker 1.12 breaks plugin because of HostConfig <https://issues.jenkins-ci.org/browse/JENKINS-36080>`_

