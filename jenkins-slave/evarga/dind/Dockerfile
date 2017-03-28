
FROM dotmpe/jenkins-slave-evarga:latest
#FROM ubuntu:trusty
#RUN apt-get update -qq && apt-get install -qqy \
#       git \
#       apt-transport-https ca-certificates \
#       openssh-server \
#       build-essential


RUN apt-get install -qqy \
       apparmor \
       iptables \
       libltdl7 \
       libsystemd-journal0 \
       aufs-tools \
       cgroup-lite

RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
RUN echo deb https://apt.dockerproject.org/repo ubuntu-trusty main > /etc/apt/sources.list
RUN apt-get update
RUN apt-get install -qqy \
        docker-engine

ARG username=jenkins
RUN adduser --system --home /home/$username --shell /bin/bash --group $username
RUN usermod jenkins -a -G sudo
RUN usermod jenkins -a -G staff
RUN usermod jenkins -a -G docker

# Flush groups
USER root
USER jenkins
USER root
USER jenkins
USER root


# Id: docker-jenkins/0.0.5-dev jenkins-slave/evarga/dind/Dockerfile
