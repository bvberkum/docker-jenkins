#!/bin/sh

# Id: docker-jenkins-mpe/0.0.1 build.sh

test -n "$1" && tag="$1" || tag=latest

# set env defaults
test -n "$image_name" || image_name=jenkins-mpe:$tag

# remove previous images and containers using this repository+tag

sudo docker images | grep ^$image_name && {

  container=$(sudo docker ps -a | grep '\<'$image_name'\>' | cut -f1 -d' ')
  test -n "$container" && {
    echo "Forcing remove of (possibly running) container"
    sudo docker rm -f $container
  }

  sudo docker rmi -f $image_name

}

echo "Building new image for $image_name"

# run
sudo docker build -t $image_name .


