#!/usr/bin/env groovy

pipeline {
  agent { label 'docker' }

  options {
    ansiColor('xterm')
  }

  environment {
    NAME = "${env.GERRIT_REFSPEC}".minus('refs/changes/').replaceAll('/','.')
      IMAGE_TAG = "$DOCKER_REGISTRY_FQDN/canvas-lms:$NAME"
  }

  stages {
    stage("Build Image") {
      steps {
        timeout(time: 20, unit: 'MINUTES') {
          sh """docker build -t $IMAGE_TAG ."""
        }
      }
    }

    /*
    stage("Publish Image") {
      when { environment name: "GERRIT_EVENT_TYPE", value: "change-merged" }
      steps {
        timeout(time: 5, unit: 'MINUTES') {
          sh """docker push $IMAGE_TAG"""
        }
      }
    }
    */
  }
}
