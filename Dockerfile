
# Id: docker-jenkins-mpe

FROM jenkins:latest

USER root
RUN usermod -aG shadow jenkins
RUN usermod -aG staff jenkins
RUN apt-get update
RUN RUNLEVEL=1 DEBIAN_FRONTEND=noninteractive \
             apt-get install -y -qq vim sudo tree tmux python

# final jenkins init
USER jenkins
COPY executors.groovy /usr/share/jenkins/ref/init.groovy.d/executors.groovy
COPY plugins.txt /plugins.txt
RUN /usr/local/bin/plugins.sh /plugins.txt

USER root

# Add jenkins job builder
RUN cd
RUN wget https://bootstrap.pypa.io/get-pip.py
RUN python get-pip.py
RUN pip install \
      ordereddict 'six>=1.5.2' PyYAML 'python-jenkins>=0.4.1' 'pbr>=0.8.2,<2.0'
RUN mkdir -vp /opt/ && chgrp staff /opt/ && chmod g+rw /opt/
RUN mkdir -vp /opt/dotmpe/docker-jenkins/
COPY init.sh /opt/dotmpe/docker-jenkins/
COPY util.sh /opt/dotmpe/docker-jenkins/
RUN mkdir -vp /src/ && chgrp staff /src/ && chmod g+rw /src/
RUN /opt/dotmpe/docker-jenkins/init.sh install_jjb

# set jenkins password and open sudo
RUN usermod -aG sudo jenkins
RUN echo 'jenkins:jenkins' | chpasswd

# Configure JJB
RUN mkdir -vp /etc/jenkins_jobs
RUN /opt/dotmpe/docker-jenkins/init.sh init_jjb localhost:8080 admin > /etc/jenkins_jobs/jenkins_jobs.ini
RUN /opt/dotmpe/docker-jenkins/init.sh init_cli localhost:8080 > /usr/local/bin/jenkins-cli
RUN chmod +x /usr/local/bin/jenkins-cli

USER jenkins

