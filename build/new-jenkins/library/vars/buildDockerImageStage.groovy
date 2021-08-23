/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

def getRailsLoadAllLocales() {
  return configuration.isChangeMerged() ? 1 : (configuration.getBoolean('rails-load-all-locales', 'false') ? 1 : 0)
}

def handleDockerBuildFailure(imagePrefix, e) {
  if (configuration.isChangeMerged() || configuration.getBoolean('upload-docker-image-failures', 'false')) {
    // DEBUG: In some cases, such as the the image build failing only on Jenkins, it can be useful to be able to
    // download the last successful layer to debug locally. If we ever start using buildkit for the relevant
    // images, then this approach will have to change as buildkit doesn't save the intermediate layers as images.

    sh(script: """
      docker tag \$(docker images | awk '{print \$3}' | awk 'NR==2') $imagePrefix-failed
      ./build/new-jenkins/docker-with-flakey-network-protection.sh push $imagePrefix-failed
    """, label: 'upload failed image')
  }

  throw e
}

def slackSendCacheBuild(block) {
  def buildStartTime = System.currentTimeMillis()

  block()

  def buildEndTime = System.currentTimeMillis()

  def buildLog = sh(script: 'cat tmp/docker-build.log', returnStdout: true).trim()
  def buildLogParts = buildLog.split('\n')
  def buildLogPartsLength = buildLogParts.size()

  // slackSend() has a ridiculously low limit of 2k, so we need to split longer logs
  // into parts.
  def i = 0
  def partitions = []
  def curPartition = []
  def maxEntries = 5

  while (i < buildLogPartsLength) {
    curPartition.add(buildLogParts[i])

    if (curPartition.size() >= maxEntries) {
      partitions.add(curPartition)

      curPartition = []
    }

    i++
  }

  if (curPartition.size() > 0) {
    partitions.add(curPartition)
  }

  for (i = 0; i < partitions.size(); i++) {
    slackSend(
      channel: '#jenkins_cache_noisy',
      message: """<${env.GERRIT_CHANGE_URL}|#${env.GERRIT_CHANGE_NUMBER}> on ${env.GERRIT_PROJECT}. Build <${env.BUILD_URL}|#${env.BUILD_NUMBER}> (${i} / ${partitions.size() - 1})
      Duration: ${buildEndTime - buildStartTime}ms
      Instance: ${env.NODE_NAME}

        ```${partitions[i].join('\n\n')}```
      """
    )
  }
}

def jsImage() {
  credentials.withStarlordCredentials {
    try {
      def cacheScope = configuration.isChangeMerged() ? env.IMAGE_CACHE_MERGE_SCOPE : env.IMAGE_CACHE_BUILD_SCOPE

      withEnv([
        "CACHE_LOAD_SCOPE=${env.IMAGE_CACHE_MERGE_SCOPE}",
        "CACHE_LOAD_FALLBACK_SCOPE=${env.IMAGE_CACHE_BUILD_SCOPE}",
        "CACHE_SAVE_SCOPE=${cacheScope}",
        "KARMA_BUILDER_PREFIX=${env.KARMA_BUILDER_PREFIX}",
        "PATCHSET_TAG=${env.PATCHSET_TAG}",
        "RAILS_LOAD_ALL_LOCALES=${getRailsLoadAllLocales()}",
        "WEBPACK_BUILDER_IMAGE=${env.WEBPACK_BUILDER_IMAGE}",
      ]) {
        sh "./build/new-jenkins/js/docker-build.sh $KARMA_RUNNER_IMAGE"
      }

      sh """
        ./build/new-jenkins/docker-with-flakey-network-protection.sh push $KARMA_RUNNER_IMAGE
        ./build/new-jenkins/docker-with-flakey-network-protection.sh push $KARMA_BUILDER_PREFIX
      """
    } catch (e) {
      handleDockerBuildFailure(KARMA_RUNNER_IMAGE, e)
    }
  }
}

def lintersImage() {
  credentials.withStarlordCredentials {
    sh './build/new-jenkins/linters/docker-build.sh $LINTERS_RUNNER_IMAGE'
    sh './build/new-jenkins/docker-with-flakey-network-protection.sh push $LINTERS_RUNNER_PREFIX'
  }
}

def premergeCacheImage() {
  credentials.withStarlordCredentials {
    withEnv([
      "CACHE_LOAD_SCOPE=${env.IMAGE_CACHE_MERGE_SCOPE}",
      "CACHE_LOAD_FALLBACK_SCOPE=${env.IMAGE_CACHE_BUILD_SCOPE}",
      "CACHE_SAVE_SCOPE=${env.IMAGE_CACHE_MERGE_SCOPE}",
      'COMPILE_ADDITIONAL_ASSETS=0',
      'JS_BUILD_NO_UGLIFY=1',
      'RAILS_LOAD_ALL_LOCALES=0',
      "RUBY_RUNNER_PREFIX=${env.RUBY_RUNNER_PREFIX}",
      "WEBPACK_BUILDER_PREFIX=${env.WEBPACK_BUILDER_PREFIX}",
      "WEBPACK_CACHE_PREFIX=${env.WEBPACK_CACHE_PREFIX}",
      "YARN_RUNNER_PREFIX=${env.YARN_RUNNER_PREFIX}",
    ]) {
      slackSendCacheBuild {
        try {
          sh 'build/new-jenkins/docker-build.sh'
        } catch (e) {
          handleDockerBuildFailure("$PATCHSET_TAG-pre-merge-failed", e)
        }
      }

      // We need to attempt to upload all prefixes here in case instructure/ruby-passenger
      // has changed between the post-merge build and this pre-merge build.
      sh(script: """
        ./build/new-jenkins/docker-with-flakey-network-protection.sh push $WEBPACK_BUILDER_PREFIX || true
        ./build/new-jenkins/docker-with-flakey-network-protection.sh push $YARN_RUNNER_PREFIX || true
        ./build/new-jenkins/docker-with-flakey-network-protection.sh push $RUBY_RUNNER_PREFIX || true
        ./build/new-jenkins/docker-with-flakey-network-protection.sh push $WEBPACK_CACHE_PREFIX
      """, label: 'upload cache images')
    }
  }
}

def patchsetImage() {
  credentials.withStarlordCredentials {
    def cacheScope = configuration.isChangeMerged() ? env.IMAGE_CACHE_MERGE_SCOPE : env.IMAGE_CACHE_BUILD_SCOPE

    slackSendCacheBuild {
      withEnv([
        "CACHE_LOAD_SCOPE=${env.IMAGE_CACHE_MERGE_SCOPE}",
        "CACHE_LOAD_FALLBACK_SCOPE=${env.IMAGE_CACHE_BUILD_SCOPE}",
        "CACHE_SAVE_SCOPE=${cacheScope}",
        "CACHE_UNIQUE_SCOPE=${env.IMAGE_CACHE_UNIQUE_SCOPE}",
        "COMPILE_ADDITIONAL_ASSETS=${configuration.isChangeMerged() ? 1 : 0}",
        "JS_BUILD_NO_UGLIFY=${configuration.isChangeMerged() ? 0 : 1}",
        "RAILS_LOAD_ALL_LOCALES=${getRailsLoadAllLocales()}",
        "RUBY_RUNNER_PREFIX=${env.RUBY_RUNNER_PREFIX}",
        "WEBPACK_BUILDER_PREFIX=${env.WEBPACK_BUILDER_PREFIX}",
        "WEBPACK_CACHE_PREFIX=${env.WEBPACK_CACHE_PREFIX}",
        "YARN_RUNNER_PREFIX=${env.YARN_RUNNER_PREFIX}",
      ]) {
        try {
          sh "build/new-jenkins/docker-build.sh $PATCHSET_TAG"
        } catch (e) {
          handleDockerBuildFailure(PATCHSET_TAG, e)
        }
      }
    }

    sh "./build/new-jenkins/docker-with-flakey-network-protection.sh push $PATCHSET_TAG"

    if (configuration.isChangeMerged()) {
      final GIT_REV = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
      sh "docker tag \$PATCHSET_TAG \$BUILD_IMAGE:${GIT_REV}"

      sh "./build/new-jenkins/docker-with-flakey-network-protection.sh push \$BUILD_IMAGE:${GIT_REV}"
    }

    sh(script: """
      ./build/new-jenkins/docker-with-flakey-network-protection.sh push $WEBPACK_BUILDER_PREFIX || true
      ./build/new-jenkins/docker-with-flakey-network-protection.sh push $YARN_RUNNER_PREFIX || true
      ./build/new-jenkins/docker-with-flakey-network-protection.sh push $RUBY_RUNNER_PREFIX || true
      ./build/new-jenkins/docker-with-flakey-network-protection.sh push $WEBPACK_CACHE_PREFIX
    """, label: 'upload cache images')
  }
}
