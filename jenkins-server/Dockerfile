
# Id: docker-jenkins/0.0.4-dev

FROM jenkins:2.0


USER root


# Update jenkins user
RUN \
  usermod -aG shadow jenkins && \
  usermod -aG staff jenkins && \
  usermod -aG sudo jenkins && \
  echo 'jenkins:jenkins' | chpasswd

# Dirs writable by Jenkins (staff group)
RUN \
  staff_group_dirs="/opt /src /opt/dotmpe/docker-jenkins /etc/jenkins_jobs"; \
  for dir in $staff_group_dirs; \
  do \
    mkdir -vp $dir && chgrp staff $dir && chmod g+rw $dir ; \
  done

# Setup some tools from apt-get
RUN apt-get update && \
  RUNLEVEL=1 DEBIAN_FRONTEND=noninteractive \
  apt-get install -y -qq \
    vim sudo tree tmux python apt-utils \
    rsync curl


# Install PIP
RUN cd && \
  wget https://bootstrap.pypa.io/get-pip.py && \
  python get-pip.py
RUN pip install docutils

# Install Node.JS (and Bower, Grunt)
RUN curl --silent --location https://deb.nodesource.com/setup_0.12 | bash -
RUN RUNLEVEL=1 DEBIAN_FRONTEND=noninteractive \
             apt-get install -y -qq \
             nodejs build-essential
RUN npm install -g bower grunt-cli


USER jenkins

# Install plugins
COPY plugins.txt /plugins.txt
RUN /usr/local/bin/plugins.sh /plugins.txt

USER root


# Prepare entry point and related scripts
COPY container-init.sh /opt/dotmpe/docker-jenkins/init.sh
RUN chmod +x /opt/dotmpe/docker-jenkins/init.sh 
COPY util.sh /opt/dotmpe/docker-jenkins/
COPY table.lib.sh /opt/dotmpe/docker-jenkins/
COPY os.lib.sh /opt/dotmpe/docker-jenkins/
COPY std.lib.sh /opt/dotmpe/docker-jenkins/


# Setup up jenkins-cli
#ARG jenkins_cli_jar_flags=-noKeyAuth
# Default: ARG jenkins_cli_jar_flags=-s http://localhost:8080 -i /home/jenkins/.ssh/id_rsa
ARG jenkins_cli_cmd_flags=
RUN /opt/dotmpe/docker-jenkins/init.sh init_cli \
      "$jenkins_cli_jar_flags" "$jenkins_cli_cmd_flags" \
    > /usr/local/bin/jenkins-cli && \
  chmod +x /usr/local/bin/jenkins-cli


RUN \
      mkdir -vp /srv/project-local \
      && chown jenkins:jenkins /srv/project-local \
      && chmod g+rw /srv \ 
      && chgrp jenkins /srv


RUN pip uninstall -y six


# Install other utils as user
# to make sure all installation prefixes are writable
USER jenkins


ENV SRC_PREFIX /src/

# Install JJB
ARG JJB_TAG=master
ARG JJB_SRC_DIR=$SRC_PREFIX/jenkins-job-builder
RUN \
  /opt/dotmpe/docker-jenkins/init.sh try_install_jjb $JJB_TAG && \
  chown jenkins:staff -R $JJB_SRC_DIR

# Configure JJB
ARG JJB_USER=jenkins
ARG JJB_PASSWORD=jenkins
RUN \
  mkdir -vp /etc/jenkins_jobs && \
  /opt/dotmpe/docker-jenkins/init.sh init_jjb localhost:8080 $JJB_USER $JJB_PASSWORD \
    > /etc/jenkins_jobs/jenkins_jobs.ini && \
  chown jenkins:staff /etc/jenkins_jobs/jenkins_jobs.ini

# Clone JJB templates repo
ARG JTB_TAG=master
ARG JTB_SRC_DIR=$SRC_PREFIX/jenkins-templated-builds
RUN cd && mkdir -vp .local/bin && \
  /opt/dotmpe/docker-jenkins/init.sh try_install_jtb $JTB_TAG


# Setup some autorun scripts to configure jenkins

COPY script/executors.groovy /usr/share/jenkins/ref/init.groovy.d/
#COPY script/set-global-build-env.groovy /usr/share/jenkins/ref/init.groovy.d/
#COPY script/set-admin-email.groovy /usr/share/jenkins/ref/init.groovy.d/
COPY script/setup-user-security.groovy /usr/share/jenkins/ref/init.groovy.d/



# Command-Line parameters
# See https://wiki.jenkins-ci.org/display/JENKINS/Starting+and+Accessing+Jenkins
# or docker run $jenkins_container --help

# Link target for "Jenkins ver 1.xxx.x" footer text
ARG company_url=http://github.com/dotmpe/docker-jenkins
ARG jenkins_install_wizard=false
ENV JAVA_OPTS -Dhudson.footerURL=$company_url \
              -Djenkins.install.runSetupWizard=$jenkins_install_wizard
#              -Djava.awt.headless=true 

# URL path prefix
ENV JENKINS_OPTS --prefix=/
#-Dhudson.model.User.allowNonExistentUserToLogin=true

#ENV JENKINS_OPTS --httpPort=-1 --httpsPort=80 --httpsCertificate=/var/lib/jenkins/cert --httpsPrivateKey=/var/lib/jenkins/pk
# FIXME: Requires some privileges for jetty (jenkins user) ENV JENKINS_OPTS --httpPort=80
# better use nginx proxy http://askubuntu.com/questions/159609/error-while-running-jetty-server-on-port-80-as-non-root-user


# Change entry point to dotmpe/jenkins-server init script
# Original ENTRYPOINT: ["/bin/tini", "--", "/usr/local/bin/jenkins.sh"]

# FIXME: rewrite script first to init in sequence. Atm, this stops CLI from
# working.
#ENTRYPOINT ["/bin/tini", "--", "/opt/dotmpe/docker-jenkins/init.sh"]
#CMD []

EXPOSE 8080




# :vim:ft=sh:
