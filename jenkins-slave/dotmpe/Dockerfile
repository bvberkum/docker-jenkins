

FROM ubuntu:14.04


ARG DEBIAN_FRONTEND=noninteractive
ARG RUNLEVEL=1



# Install and configure a basic SSH server
RUN apt-get update &&\
    apt-get install -y openssh-server &&\
    apt-get clean -y && rm -rf /var/lib/apt/lists/* &&\
    sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd &&\
    mkdir -p /var/run/sshd

# Install JDK 7 (latest edition)
RUN apt-get update &&\
    apt-get install -y openjdk-7-jdk &&\
    apt-get clean -y


# Install some build slave essentials
RUN apt-get update &&\
    apt-get install -y build-essential git python &&\
    apt-get clean -y

# Install PIP
RUN cd && \
  wget https://bootstrap.pypa.io/get-pip.py && \
  python get-pip.py


ARG username=jenkins

# Add main user

RUN adduser --system --home /home/$username --shell /bin/bash --group $username
RUN echo "$username:$username" | chpasswd

RUN mkdir /home/$username/project
RUN chown -R $username:$username /home/$username/

# Update jenkins user
RUN \
  usermod -aG shadow $username && \
  usermod -aG staff $username && \
  usermod -aG sudo $username && \
  echo "$username:$username" | chpasswd


USER $username

# Install Basher
RUN cd \
  && git clone https://github.com/basherpm/basher.git .basher \
  && echo 'export PATH="$HOME/.basher/bin:$PATH"' >> /home/$username/.bash_profile

# Add user install path
RUN echo 'export PATH="$HOME/.local/bin:$PATH"' >> /home/$username/.bash_profile


USER root

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]


