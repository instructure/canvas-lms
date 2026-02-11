#!/usr/bin/env groovy

/*
 * Copyright (C) 2026 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

def getCanvasBuildsRefspec() {
  def defaultValue = env.GERRIT_BRANCH.contains('stable/') ? env.GERRIT_BRANCH : 'master'
  return commitMessageFlag('canvas-builds-refspec') as String ?: defaultValue
}

def buildParameters = [
  string(name: 'GERRIT_REFSPEC', value: "${env.GERRIT_REFSPEC}"),
  string(name: 'GERRIT_EVENT_TYPE', value: "${env.GERRIT_EVENT_TYPE}"),
  string(name: 'GERRIT_PROJECT', value: "${env.GERRIT_PROJECT}"),
  string(name: 'GERRIT_BRANCH', value: "${env.GERRIT_BRANCH}"),
  string(name: 'GERRIT_CHANGE_NUMBER', value: "${env.GERRIT_CHANGE_NUMBER}"),
  string(name: 'GERRIT_CHANGE_SUBJECT', value: "${env.GERRIT_CHANGE_SUBJECT}"),
  string(name: 'GERRIT_PATCHSET_NUMBER', value: "${env.GERRIT_PATCHSET_NUMBER}"),
  string(name: 'GERRIT_PATCHSET_REVISION', value: "${env.GERRIT_PATCHSET_REVISION}"),
  string(name: 'GERRIT_EVENT_ACCOUNT_NAME', value: "${env.GERRIT_EVENT_ACCOUNT_NAME}"),
  string(name: 'GERRIT_EVENT_ACCOUNT_EMAIL', value: "${env.GERRIT_EVENT_ACCOUNT_EMAIL}"),
  string(name: 'GERRIT_CHANGE_COMMIT_MESSAGE', value: "${env.GERRIT_CHANGE_COMMIT_MESSAGE}"),
  string(name: 'GERRIT_HOST', value: "${env.GERRIT_HOST}"),
  string(name: 'GERGICH_PUBLISH', value: "${env.GERGICH_PUBLISH}"),
  string(name: 'MASTER_BOUNCER_RUN', value: "${env.MASTER_BOUNCER_RUN}"),
  string(name: 'CRYSTALBALL_MAP_S3_VERSION', value: "${env.CRYSTALBALL_MAP_S3_VERSION}")
]

commitMessageFlag.setEnabled(env.GERRIT_EVENT_TYPE != 'change-merged')

library "canvas-builds-library@${getCanvasBuildsRefspec()}"
loadLocalLibrary('local-lib', 'build/new-jenkins/library')

commitMessageFlag.setDefaultValues(commitMessageFlagDefaults() + commitMessageFlagPrivateDefaults())

pipeline {
  agent { label 'canvas-docker' }

  options {
    timeout(time: 1, unit: 'HOURS')
    ansiColor('xterm')
    timestamps()
    lock (label: 'canvas_build_global_mutex', quantity: 1)
  }

  environment {
    GERRIT_PORT = '29418'
    GERRIT_URL = "$GERRIT_HOST:$GERRIT_PORT"
    BUILD_REGISTRY_FQDN = configuration.buildRegistryFQDN()
    BUILD_IMAGE = configuration.buildRegistryPath()
    POSTGRES = configuration.postgres()
    POSTGRES_CLIENT = configuration.postgresClient()
    RSPEC_PROCESSES = commitMessageFlag('rspecq-processes').asType(Integer)
    GERRIT_CHANGE_ID = pipelineHelpers.getChangeId()

    // e.g. postgres-12-ruby-2.6
    TAG_SUFFIX = imageTag.suffix()

    // e.g. canvas-lms:01.123456.78-postgres-12-ruby-2.6
    PATCHSET_TAG = imageTag.patchset()

    // e.g. canvas-lms:master when not on another branch
    MERGE_TAG = imageTag.mergeTag()

    // e.g. canvas-lms:01.123456.78; this is for consumers like Portal 2 who want to build a patchset
    EXTERNAL_TAG = imageTag.externalTag()

    RUBY = configuration.ruby() // RUBY_VERSION is a reserved keyword for ruby installs

    FORCE_CRYSTALBALL = "${commitMessageFlag('force-crystalball').asBooleanInteger()}"

    BASE_RUNNER_PREFIX = configuration.buildRegistryPath('base-runner')
    DYNAMODB_PREFIX = configuration.buildRegistryPath('dynamodb-migrations')
    KARMA_RUNNER_PREFIX = configuration.buildRegistryPath('karma-runner')
    LINTERS_RUNNER_PREFIX = configuration.buildRegistryPath('linters-runner')
    POSTGRES_PREFIX = configuration.buildRegistryPath('postgres-migrations')
    RUBY_RUNNER_PREFIX = configuration.buildRegistryPath('ruby-runner')
    YARN_RUNNER_PREFIX = configuration.buildRegistryPath('yarn-runner')
    WEBPACK_BUILDER_PREFIX = configuration.buildRegistryPath('webpack-builder')
    WEBPACK_ASSETS_PREFIX = configuration.buildRegistryPath('webpack-assets')
    WEBPACK_CACHE_PREFIX = configuration.buildRegistryPath('webpack-cache')

    IMAGE_CACHE_BUILD_SCOPE = configuration.gerritChangeNumber()
    IMAGE_CACHE_MERGE_SCOPE = configuration.gerritBranchSanitized()
    IMAGE_CACHE_UNIQUE_SCOPE = "${imageTagVersion()}-$TAG_SUFFIX"

    DYNAMODB_IMAGE_TAG = "$DYNAMODB_PREFIX:$IMAGE_CACHE_UNIQUE_SCOPE"
    POSTGRES_IMAGE_TAG = "$POSTGRES_PREFIX:$IMAGE_CACHE_UNIQUE_SCOPE"
    WEBPACK_BUILDER_IMAGE = "$WEBPACK_BUILDER_PREFIX:$IMAGE_CACHE_UNIQUE_SCOPE"
    WEBPACK_ASSETS_IMAGE = "$WEBPACK_ASSETS_PREFIX:$IMAGE_CACHE_UNIQUE_SCOPE"

    DYNAMODB_MERGE_IMAGE = "$DYNAMODB_PREFIX:$IMAGE_CACHE_MERGE_SCOPE-${env.RSPEC_PROCESSES ?: '4'}"
    KARMA_RUNNER_IMAGE = "$KARMA_RUNNER_PREFIX:$IMAGE_CACHE_UNIQUE_SCOPE"
    KARMA_MERGE_IMAGE = "$KARMA_RUNNER_PREFIX:$IMAGE_CACHE_MERGE_SCOPE"
    LINTERS_RUNNER_IMAGE = "$LINTERS_RUNNER_PREFIX:$IMAGE_CACHE_UNIQUE_SCOPE"
    POSTGRES_MERGE_IMAGE = "$POSTGRES_PREFIX:$IMAGE_CACHE_MERGE_SCOPE-${env.RSPEC_PROCESSES ?: '4'}"

    // This is primarily for the plugin build
    // for testing canvas-lms changes against plugin repo changes
    CANVAS_BUILDS_REFSPEC = getCanvasBuildsRefspec()
    CANVAS_LMS_REFSPEC = pipelineHelpers.getCanvasLmsRefspec()
    DOCKER_WORKDIR = pipelineHelpers.getDockerWorkDir()
    LOCAL_WORKDIR = pipelineHelpers.getLocalWorkDir()

    // TEST_CACHE_CLASSES is consumed by config/environments/test.rb
    // to decide whether to allow class reloading or not.
    // in local development we usually want this unset or set to '0' because
    // we want spring to be able to reload classes between
    // spec runs, but this is expensive when running all the
    // specs for the build.  EVERYWHERE in the build we want
    // to be able to cache classes because they don't change while the build
    // is running and should never be reloaded.
    TEST_CACHE_CLASSES = '1'
  }

  stages {
    stage('Configure Build') {
      steps {
        script {
          buildParameters = pipelineHelpers.configureBuildStage(buildParameters)
        }
      }
    }

    stage('Cleanup Workspace') {
      steps {
        script {
          pipelineHelpers.cleanupWorkspace()
        }
      }
    }

    stage('Setup') {
      steps {
        script {
          def stageName = 'Setup'
          def startTime = System.currentTimeMillis()
          try {
            filesChangedStage.reset()
            buildDockerImageStage.preloadCacheImagesAsync()
            setupStage()
          } finally {
            buildSummaryReport.trackStage(stageName, startTime)
          }
        }
      }
    }

    stage('Rebase') {
      when {
        environment name: 'GERRIT_PROJECT', value: 'canvas-lms'
        expression { !configuration.isChangeMerged() }
      }
      options { timeout(time: 2, unit: 'MINUTES') }
      steps {
        script {
          def stageName = 'Rebase'
          def startTime = System.currentTimeMillis()
          try {
            rebaseStage()
          } finally {
            buildSummaryReport.trackStage(stageName, startTime)
          }
        }
      }
    }

    stage('Detect Files Changed (Pre-Build)') {
      options { timeout(time: 2, unit: 'MINUTES') }
      steps {
        script {
          def stageName = 'Detect Files Changed (Pre-Build)'
          def startTime = System.currentTimeMillis()
          try {
            filesChangedStage.preBuild()
          } finally {
            buildSummaryReport.trackStage(stageName, startTime)
          }
        }
      }
    }

    stage('Build Docker Image (Pre-Merge)') {
      when {
        expression { configuration.isChangeMerged() }
      }
      options { timeout(time: 20, unit: 'MINUTES') }
      steps {
        script {
          def stageName = 'Build Docker Image (Pre-Merge)'
          def startTime = System.currentTimeMillis()
          try {
            buildDockerImageStage.premergeCacheImage()
          } finally {
            buildSummaryReport.trackStage(stageName, startTime)
          }
        }
      }
    }

    stage('Build Docker Image') {
      options { timeout(time: 20, unit: 'MINUTES') }
      steps {
        script {
          def stageName = 'Build Docker Image'
          def startTime = System.currentTimeMillis()
          try {
            def startStep = '''
              docker run -dt --name general-build-container --volume $(pwd)/$LOCAL_WORKDIR/.git:$DOCKER_WORKDIR/.git -e RAILS_ENV=test $PATCHSET_TAG bash -c "sleep infinity"
              docker exec -dt general-build-container bin/rails graphql:schema
            '''

            @SuppressWarnings('GStringExpressionWithinString')
            def crystalballStep = '''
              diffFrom=$(git --git-dir $LOCAL_WORKDIR/.git rev-parse $GERRIT_PATCHSET_REVISION^1)
              # crystalball will fail without adding $DOCKER_WORKDIR to safe.directory
              docker exec -t general-build-container bash -c "git config --global --add safe.directory ${DOCKER_WORKDIR%/}"
              docker exec -dt \
                              -e CRYSTALBALL_DIFF_FROM=$diffFrom \
                              -e CRYSTALBALL_DIFF_TO=$GERRIT_PATCHSET_REVISION \
                              -e CRYSTALBALL_REPO_PATH=$DOCKER_WORKDIR \
                              -e FORCE_CRYSTALBALL=$FORCE_CRYSTALBALL \
                              general-build-container bundle exec crystalball --dry-run
            '''

            def finalStep = '''
              docker exec -t general-build-container ps aww
            '''

            def asyncSteps = [
              startStep,
              !configuration.isChangeMerged() && env.GERRIT_REFSPEC != 'refs/heads/master' ? crystalballStep : '',
              finalStep
            ]

            buildDockerImageStage.patchsetImage(asyncSteps.join('\n'))
          } finally {
            buildSummaryReport.trackStage(stageName, startTime)
          }
        }
      }
    }

    stage('Detect Files Changed (Post-Build)') {
      options { timeout(time: 2, unit: 'MINUTES') }
      steps {
        script {
          def stageName = 'Detect Files Changed (Post-Build)'
          def startTime = System.currentTimeMillis()
          try {
            filesChangedStage.postBuild()

            env.HAS_BUNDLE_FILES = filesChangedStage.hasBundleFiles()
            env.HAS_YARN_FILES = filesChangedStage.hasYarnFiles()
            env.HAS_JS_FILES = filesChangedStage.hasJsFiles()
            env.HAS_GRAPHQL_FILES = filesChangedStage.hasGraphqlFiles()
            env.HAS_GROOVY_FILES = filesChangedStage.hasGroovyFiles()
          } finally {
            buildSummaryReport.trackStage(stageName, startTime)
          }
        }
      }
    }

    stage('Run Migrations') {
      options { timeout(time: 10, unit: 'MINUTES') }
      steps {
        script {
          def stageName = 'Run Migrations'
          def startTime = System.currentTimeMillis()
          try {
            runMigrationsStage()
          } finally {
            buildSummaryReport.trackStage(stageName, startTime)
          }
        }
      }
    }

    stage('Generate Crystalball Prediction') {
      when {
        expression { !configuration.isChangeMerged() && env.GERRIT_REFSPEC != 'refs/heads/master' }
      }
      options { timeout(time: 2, unit: 'MINUTES') }
      steps {
        script {
          def stageName = 'Generate Crystalball Prediction'
          def startTime = System.currentTimeMillis()
          try {
            if (filesChangedStage.hasErbFiles()) {
              echo 'Ignoring Crystalball prediction due to .erb file changes'
              env.SKIP_CRYSTALBALL = 1
              return
            }

            try {
              sh '''#!/bin/bash
                set -ex

                while docker exec -t general-build-container ps aww | grep crystalball; do
                  sleep 0.1
                done

                docker exec -t general-build-container bash -c 'cat log/crystalball.log'
                docker cp $(docker ps -qa -f name=general-build-container):/usr/src/app/crystalball_spec_list.txt ./tmp/crystalball_spec_list.txt
              '''
              archiveArtifacts allowEmptyArchive: true, artifacts: 'tmp/crystalball_spec_list.txt'

              sh 'grep ":timestamp:" crystalball_map.yml | sed "s/:timestamp: //g" > ./tmp/crystalball_map_version.txt'
              archiveArtifacts allowEmptyArchive: true, artifacts: 'tmp/crystalball_map_version.txt'
            } catch (Exception e) {
              // default to full run of specs
              sh 'echo -n "." > tmp/crystalball_spec_list.txt'
              sh 'echo -n "broken map, defaulting to run all tests" > tmp/crystalball_map_version.txt'

              archiveArtifacts allowEmptyArchive: true, artifacts: 'tmp/crystalball_spec_list.txt, tmp/crystalball_map_version.txt'

              slackSend(
                channel: '#crystalball-noisy',
                color: 'danger',
                message: "${env.JOB_NAME} <${pipelineHelpers.getSummaryUrl()}|#${env.BUILD_NUMBER}>\n\nFailed to generate prediction!"
              )
            }
          } finally {
            buildSummaryReport.trackStage(stageName, startTime)
          }
        }
      }
    }

    stage('Locales Only Changes') {
      when {
        expression { !configuration.isChangeMerged() }
        environment name: 'GERRIT_PROJECT', value: 'canvas-lms'
        expression {
          sh(script: "${WORKSPACE}/build/new-jenkins/locales-changes.sh", returnStatus: true) == 0
        }
      }
      steps {
        script {
          submitGerritReview('--label Lint-Review=-2', 'This commit contains only changes to config/locales/, this could be a bad sign!')
        }
      }
    }

    stage('Webpack Bundle Size Check') {
      when {
        expression { configuration.isChangeMerged() }
      }
      options { timeout(time: 20, unit: 'MINUTES') }
      steps {
        script {
          def stageName = 'Webpack Bundle Size Check'
          def startTime = System.currentTimeMillis()
          try {
            webpackStage.calcBundleSizes()
          } finally {
            buildSummaryReport.trackStage(stageName, startTime)
          }
        }
      }
    }

    stage('Parallel Build Images and Run Tests') {
      parallel {
        stage('ARM64 Builder') {
          when {
            allOf {
              expression { shouldStageRun('ARM64') }
              expression { configuration.isChangeMerged() }
            }
          }
          agent { label 'docker-arm64' }
          options {
            // setupStage() handles the git checkout, so we skip the default checkout
            skipDefaultCheckout()
          }
          steps {
            script {
              def stageName = 'ARM64 Builder'
              def startTime = System.currentTimeMillis()
              try {
                setupStage()
                buildDockerImageStage.patchsetImage('', '-arm64')
              } finally {
                buildSummaryReport.trackStage(stageName, startTime)
              }

              stageName = 'Augment ARM64 Manifest'
              startTime = System.currentTimeMillis()
              try {
                buildDockerImageStage.augmentArm64Manifest()
              } finally {
                buildSummaryReport.trackStage(stageName, startTime)
              }
            }
          }
        }

        stage('Javascript Flow') {
          when {
            allOf {
              expression { shouldStageRun('Javascript') }
              expression {
                configuration.isChangeMerged() ||
                commitMessageFlag('force-failure-js') as Boolean ||
                (!configuration.isChangeMerged() && (filesChangedStage.hasGraphqlFiles() || filesChangedStage.hasJsFiles()))
              }
            }
          }
          stages {
            stage('Javascript (Build Image)') {
              steps {
                script {
                  def stageName = 'Javascript (Build Image)'
                  def startTime = System.currentTimeMillis()
                  try {
                    buildDockerImageStage.jsImage()
                  } finally {
                    buildSummaryReport.trackStage(stageName, startTime)
                  }
                }
              }
            }

            stage('Javascript') {
              steps {
                script {
                  pipelineHelpers.runTestSuite(
                    'Javascript',
                    '/Canvas/test-suites/JS',
                    buildParameters + [string(name: 'KARMA_RUNNER_IMAGE', value: env.KARMA_RUNNER_IMAGE)]
                  )
                }
              }
            }
          }
        }

        stage('Linters Flow') {
          when {
            expression { shouldStageRun('Linters') }
          }
          stages {
            stage('Linters (Build Image)') {
              steps {
                script {
                  def stageName = 'Linters (Build Image)'
                  def startTime = System.currentTimeMillis()
                  try {
                    timeout(time: 4, unit: 'MINUTES') {
                      buildDockerImageStage.lintersImage()
                    }
                  } finally {
                    buildSummaryReport.trackStage(stageName, startTime)
                  }
                }
              }
            }

            stage('Linters') {
              steps {
                script {
                  if (configuration.isChangeMerged() || env.GERRIT_CHANGE_ID != '0') {
                    lintersStage.provisionDocker()
                    lintersStage.runLintersInline()
                  }
                }
              }
            }
          }
        }

        stage('Consumer Smoke Test') {
          when {
            expression { shouldStageRun('Consumer') }
          }
          steps {
            script {
              def stageName = 'Consumer Smoke Test'
              def startTime = System.currentTimeMillis()
              try {
                sh 'build/new-jenkins/consumer-smoke-test.sh'
              } finally {
                buildSummaryReport.trackStage(stageName, startTime)
              }
            }
          }
        }

        stage('Run i18n:extract') {
          when {
            allOf {
              expression { shouldStageRun('i18n') }
              expression { configuration.isChangeMerged() }
            }
          }
          steps {
            script {
              def stageName = 'Run i18n:extract'
              def startTime = System.currentTimeMillis()
              try {
                buildDockerImageStage.i18nExtract()
              } finally {
                buildSummaryReport.trackStage(stageName, startTime)
              }
            }
          }
        }

        stage('Local Docker Dev Build') {
          when {
            allOf {
              expression { shouldStageRun('DockerDev') }
              environment name: 'GERRIT_PROJECT', value: 'canvas-lms'
              expression { filesChangedStage.hasDockerDevFiles() }
            }
          }
          steps {
            script {
              pipelineHelpers.runTestSuite(
                'Local Docker Dev Build',
                '/Canvas/test-suites/local-docker-dev-smoke',
                buildParameters
              )
            }
          }
        }

        stage('Contract Tests') {
          when {
            expression { shouldStageRun('Contract') }
          }
          steps {
            script {
              pipelineHelpers.runTestSuite(
                'Contract Tests',
                '/Canvas/test-suites/contract-tests',
                buildParameters + [
                  string(name: 'DYNAMODB_IMAGE_TAG', value: "${env.DYNAMODB_IMAGE_TAG}"),
                  string(name: 'POSTGRES_IMAGE_TAG', value: "${env.POSTGRES_IMAGE_TAG}")
                ]
              )
            }
          }
        }

        stage('Flakey Spec Catcher') {
          when {
            allOf {
              expression { shouldStageRun('FSC') }
              expression { !configuration.isChangeMerged() }
              anyOf {
                expression { filesChangedStage.hasSpecFiles() }
                expression { commitMessageFlag('force-failure-fsc') as Boolean }
              }
            }
          }
          steps {
            script {
              pipelineHelpers.runTestSuite(
                'Flakey Spec Catcher',
                '/Canvas/test-suites/flakey-spec-catcher',
                buildParameters + [
                  string(name: 'DYNAMODB_IMAGE_TAG', value: "${env.DYNAMODB_IMAGE_TAG}"),
                  string(name: 'POSTGRES_IMAGE_TAG', value: "${env.POSTGRES_IMAGE_TAG}")
                ]
              )
            }
          }
        }

        stage('Vendored Gems') {
          when {
            expression { shouldStageRun('Vendored') }
          }
          steps {
            script {
              pipelineHelpers.runTestSuite(
                'Vendored Gems',
                '/Canvas/test-suites/vendored-gems',
                buildParameters + [
                  string(name: 'DYNAMODB_IMAGE_TAG', value: "${env.DYNAMODB_IMAGE_TAG}"),
                  string(name: 'POSTGRES_IMAGE_TAG', value: "${env.POSTGRES_IMAGE_TAG}")
                ]
              )
            }
          }
        }

        stage('RspecQ Tests') {
          when {
            expression { shouldStageRun('RspecQ') }
          }
          steps {
            script {
              pipelineHelpers.runTestSuite(
                'RspecQ Tests',
                '/Canvas/test-suites/test-queue',
                buildParameters + [
                  string(name: 'DYNAMODB_IMAGE_TAG', value: "${env.DYNAMODB_IMAGE_TAG}"),
                  string(name: 'POSTGRES_IMAGE_TAG', value: "${env.POSTGRES_IMAGE_TAG}"),
                  string(name: 'SKIP_CRYSTALBALL', value: "${env.SKIP_CRYSTALBALL || setupStage.hasGemOverrides()}"),
                  string(name: 'RSPECQ_UPDATE_TIMINGS', value: "${env.RSPECQ_UPDATE_TIMINGS || 0}"),
                  string(name: 'UPSTREAM_TAG', value: "${env.BUILD_TAG}"),
                  string(name: 'UPSTREAM', value: "${env.JOB_NAME}")
                ]
              )
            }
          }
        }
      }
    }
  }

  post {
    always {
      script {
        // Restore the correct build result for skipped builds (e.g., translation builds)
        if (env.SKIP_BUILD == 'true' && env.SKIP_BUILD_RESULT) {
          currentBuild.result = env.SKIP_BUILD_RESULT
          echo "Build was skipped - setting result to ${env.SKIP_BUILD_RESULT}"
        }

        if (env.SKIP_BUILD != 'true') {
          // Only run the post-build cleanup if the build wasn't skipped, since skipped builds may not have set up docker or other resources
          pipelineHelpers.postBuildAlways()
        }
      }
    }

    success {
      script {
        pipelineHelpers.maybeSlackSendSuccess()
      }
    }

    failure {
      script {
        if (env.SKIP_BUILD != 'true') {
          pipelineHelpers.maybeSlackSendFailure()
          pipelineHelpers.maybeRetrigger()
        }
      }
    }
  }
}
