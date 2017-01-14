
if (!Build_Tag) {
  Build_Tag = '2.0'
}
if (!Build_Env) {
  Build_Env = 'dev'
}


// Ask for Docker-in-Docker or other Docker host Jenkins slave
println "Waiting for node 'dind || docker-host'"

node("dind || docker-host") {

  stage('Checkout') {

    sh '''
      echo DCKR_JNK_VERSION=$DCKR_JNK_VERSION
      echo DCKR_JNK_JJB_FILE=$DCKR_JNK_JJB_FILE
    '''
  
    String checkout_dir="../workspace@script"
    if (fileExists(checkout_dir)) {
      dir checkout_dir
    } else {
      checkout scm
    }

    sh "mkdir -vp build"

    // The rest of this stage deals with build name/description
    rev = getSh "git rev-parse HEAD"
    ref = getSh "git show-ref | grep -v remotes | grep ^${rev} | cut -d ' ' -f 2 | head -n 1"
    branchName = getSh "echo ${ref} | cut -d '/' -f 3- "
	  git_descr = getSh "git describe --always"
	  rev_abbrev = getSh "echo $rev | cut -c1-11"

    currentBuild.displayName = "${git_descr} b${env.BUILD_NUMBER}"
    currentBuild.description = \
      "$rev_abbrev ($branchName)  ${Build_Env}:${Build_Tag}  Job version: $DCKR_JNK_VERSION"
  }


  stage('Build') {

    env.env = Build_Env
    env.tag = Build_Tag

    env.Build_Image = 1
    env.Build_Remove_Existing = 1
    env.Build_Only = 1
    env.DCKR_VOL = pwd tmp: true

    sh 'echo env=$env'
    sh 'test -n "$env"'

    println "Building new bvberkum/jenkins-{server,slave*}:latest"

    sh """#!/bin/bash

    ./inits.sh server
    ./inits.sh slave
    ./inits.sh slave-dind
    """
  }

  if (Build_Env == 'dev') {
    echo "Development build: starting server with production data for evaluation"
    sh """#!/bin/bash

    # export prod
    ./jenkins-user-script.sh /var/jenkins_home $hostname-$shostname"

    # run with import of duplicated prod data
    Run_Import_Home_Volume=build/export.tar vendor=bvberkum ./run.sh ${Build_Env} ${Build_Tag}
    """
  }

  if (Build_Env == 'acc') {
    echo "Acceptation build: starting server with production data for evaluation"
    sh "Run_Import_Home_Volume=jenkins-prod-home vendor=bvberkum ./run.sh ${Build_Env} ${Build_Tag}"
  }
}


def getSh(cmd) {
	sh "sh -c \"( $cmd ) > build/cmd-out\""
	// returun output minus trailing whitespace
	return readFile("build/cmd-out").trim()
}


// vim:ft=groovy:
