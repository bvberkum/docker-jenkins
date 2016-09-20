

FROM bvberkum/jenkins-slave-dotmpe:latest


RUN apt-get update -qq && apt-get install -qqy \
       git \
       apt-transport-https ca-certificates \
       openssh-server \
       build-essential \
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


RUN usermod jenkins -a -G users
RUN usermod jenkins -a -G docker


