
stage 'Prerun'

if (!Build_Version) {
  Build_Version = '2.0'
}
if (!Build_Tag) {
  Build_Tag = 'auto'
}

println "Waiting for node 'dind || docker-host'"

node("dind || docker-host") {

  stage 'Checkout'
  checkout scm

  stage 'Build'

  env.env = Build_Tag
  env.tag = Build_Version
  env.Build_Image = 1
  env.Build_Remove_Existing = 1
  env.Build_Only = 1
  env.DCKR_VOL = pwd tmp: true

  sh 'echo $env'
  sh 'test -n "$env"'

  sh """#!/bin/bash

  # TODO: ./inits.sh server-mpe
  ./inits.sh slave-mpe
  ./inits.sh slave-mpe-dind
  """
}


// vim:ft=groovy:
