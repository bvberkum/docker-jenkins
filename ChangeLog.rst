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
  In progress.


.. [#] `docker 1.12 breaks plugin because of HostConfig <https://issues.jenkins-ci.org/browse/JENKINS-36080>`_

