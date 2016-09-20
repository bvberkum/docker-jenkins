
if (!Build_Version) {
  Build_Version = '2.0'
}
if (!Build_Tag) {
  Build_Tag = 'dev'
}

// Ask for Docker-in-Docker or other Docker host Jenkins slave
println "Waiting for node 'dind || docker-host'"

node("dind || docker-host") {


  stage 'Checkout'
  
  String checkout_dir="../workspace@script"
  if (fileExists(checkout_dir)) {
    dir checkout_dir
  } else {
    checkout scm
  }


  stage 'Build'

  env.env = Build_Tag
  env.tag = Build_Version
  env.Build_Image = 1
  env.Build_Remove_Existing = 1
  env.Build_Only = 1
  env.DCKR_VOL = pwd tmp: true

  sh 'echo env=$env'
  sh 'test -n "$env"'

  sh """#!/bin/bash

  ./inits.sh server
  ./inits.sh slave
  ./inits.sh slave-dind
  """



}


// vim:ft=groovy:
