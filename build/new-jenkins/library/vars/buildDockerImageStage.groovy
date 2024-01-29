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

def getFuzzyTagSuffix() {
  return "fuzzy-${env.IMAGE_CACHE_MERGE_SCOPE}"
}

def getRailsLoadAllLocales() {
  return configuration.isChangeMerged() ? 1 : commitMessageFlag('rails-load-all-locales').asBooleanInteger()
}

def handleDockerBuildFailure(imagePrefix, e) {
  if (configuration.isChangeMerged() || commitMessageFlag('upload-docker-image-failures') as Boolean) {
    // DEBUG: In some cases, such as the the image build failing only on Jenkins, it can be useful to be able to
    // download the last successful layer to debug locally. If we ever start using buildkit for the relevant
    // images, then this approach will have to change as buildkit doesn't save the intermediate layers as images.

    sh(script: """
      docker tag \$(docker images | awk '{print \$3}' | awk 'NR==2') $imagePrefix-failed
      ./build/new-jenkins/docker-with-flakey-network-protection.sh push -a $imagePrefix-failed
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
        "PATCHSET_TAG=${env.PATCHSET_TAG}",
        "RAILS_LOAD_ALL_LOCALES=${getRailsLoadAllLocales()}",
        "WEBPACK_BUILDER_IMAGE=${env.WEBPACK_BUILDER_IMAGE}",
        "CRYSTALBALL_MAP=${env.CRYSTALBALL_MAP}"
      ]) {
        sh "./build/new-jenkins/js/docker-build.sh $KARMA_RUNNER_IMAGE"
      }

      sh """
        ./build/new-jenkins/docker-with-flakey-network-protection.sh push $KARMA_RUNNER_IMAGE
      """
    } catch (e) {
      handleDockerBuildFailure(KARMA_RUNNER_IMAGE, e)
    }
  }
}

def lintersImage() {
  credentials.withStarlordCredentials {
    sh './build/new-jenkins/linters/docker-build.sh $LINTERS_RUNNER_IMAGE'
    sh './build/new-jenkins/docker-with-flakey-network-protection.sh push -a $LINTERS_RUNNER_PREFIX'
  }
}

def preloadCacheImagesAsync() {
  // Start loading webpack-assets immediately in case this build will re-use it.
  libraryScript.load('bash/docker-with-flakey-network-protection.sh', '/tmp/docker-with-flakey-network-protection.sh')

  sh """#!/bin/bash
    /tmp/docker-with-flakey-network-protection.sh pull starlord.inscloudgate.net/jenkins/dockerfile:1.5.2 &
    {
      /tmp/docker-with-flakey-network-protection.sh pull ${env.WEBPACK_ASSETS_PREFIX}:${getFuzzyTagSuffix()}
      /tmp/docker-with-flakey-network-protection.sh pull ${env.WEBPACK_BUILDER_PREFIX}:${getFuzzyTagSuffix()}
    } &
    /tmp/docker-with-flakey-network-protection.sh pull ${env.WEBPACK_CACHE_PREFIX}:${getFuzzyTagSuffix()} &
  """
}

def premergeCacheImage() {
  credentials.withStarlordCredentials {
    withEnv([
      "BASE_RUNNER_PREFIX=${env.BASE_RUNNER_PREFIX}",
      "CACHE_LOAD_SCOPE=${env.IMAGE_CACHE_MERGE_SCOPE}",
      "CACHE_LOAD_FALLBACK_SCOPE=${env.IMAGE_CACHE_BUILD_SCOPE}",
      "CACHE_SAVE_SCOPE=${env.IMAGE_CACHE_MERGE_SCOPE}",
      'COMPILE_ADDITIONAL_ASSETS=0',
      "CRYSTALBALL_MAP=${env.CRYSTALBALL_MAP}",
      'SKIP_SOURCEMAPS=0',
      'RAILS_LOAD_ALL_LOCALES=0',
      "RUBY_RUNNER_PREFIX=${env.RUBY_RUNNER_PREFIX}",
      "WEBPACK_BUILDER_PREFIX=${env.WEBPACK_BUILDER_PREFIX}",
      "WEBPACK_ASSETS_FUZZY_SAVE_TAG=${env.WEBPACK_ASSETS_PREFIX}:${getFuzzyTagSuffix()}",
      "WEBPACK_ASSETS_PREFIX=${env.WEBPACK_ASSETS_PREFIX}",
      "WEBPACK_BUILDER_FUZZY_SAVE_TAG=${env.WEBPACK_BUILDER_PREFIX}:${getFuzzyTagSuffix()}",
      "WEBPACK_CACHE_FUZZY_SAVE_TAG=${env.WEBPACK_CACHE_PREFIX}:${getFuzzyTagSuffix()}",
      "YARN_RUNNER_PREFIX=${env.YARN_RUNNER_PREFIX}",
      "READ_BUILD_CACHE=0",
      "WRITE_BUILD_CACHE=1",
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
        ./build/new-jenkins/docker-with-flakey-network-protection.sh push -a $WEBPACK_BUILDER_PREFIX || true
        ./build/new-jenkins/docker-with-flakey-network-protection.sh push -a $YARN_RUNNER_PREFIX || true
        ./build/new-jenkins/docker-with-flakey-network-protection.sh push -a $RUBY_RUNNER_PREFIX || true
        ./build/new-jenkins/docker-with-flakey-network-protection.sh push -a $BASE_RUNNER_PREFIX || true
        ./build/new-jenkins/docker-with-flakey-network-protection.sh push -a $WEBPACK_ASSETS_PREFIX
        ./build/new-jenkins/docker-with-flakey-network-protection.sh push -a $WEBPACK_CACHE_PREFIX || true
      """, label: 'upload cache images')
    }
  }
}

def patchsetImage(asyncStepsStr = '', platformSuffix = '') {
  credentials.withStarlordCredentials {
    def cacheScope = configuration.isChangeMerged() ? env.IMAGE_CACHE_MERGE_SCOPE : env.IMAGE_CACHE_BUILD_SCOPE
    def readBuildCache = configuration.isChangeMerged() ? 0 : 1
    def webpackAssetsFuzzyTag = configuration.isChangeMerged() ? "" : "${env.WEBPACK_ASSETS_PREFIX}:${getFuzzyTagSuffix()}"
    def webpackCacheFuzzyTag = configuration.isChangeMerged() ? "" : "${env.WEBPACK_CACHE_PREFIX}:${getFuzzyTagSuffix()}"

    slackSendCacheBuild {
      withEnv([
        "BASE_RUNNER_PREFIX=${env.BASE_RUNNER_PREFIX}",
        "CACHE_LOAD_SCOPE=${env.IMAGE_CACHE_MERGE_SCOPE}",
        "CACHE_LOAD_FALLBACK_SCOPE=${env.IMAGE_CACHE_BUILD_SCOPE}",
        "CACHE_SAVE_SCOPE=${cacheScope}",
        "CACHE_UNIQUE_SCOPE=${env.IMAGE_CACHE_UNIQUE_SCOPE}",
        "COMPILE_ADDITIONAL_ASSETS=${configuration.isChangeMerged() ? 1 : 0}",
        "CRYSTALBALL_MAP=${env.CRYSTALBALL_MAP}",
        "SKIP_SOURCEMAPS=0",
        "PLATFORM_SUFFIX=${platformSuffix}",
        "RAILS_LOAD_ALL_LOCALES=${getRailsLoadAllLocales()}",
        "RUBY_RUNNER_PREFIX=${env.RUBY_RUNNER_PREFIX}",
        "WEBPACK_BUILDER_PREFIX=${env.WEBPACK_BUILDER_PREFIX}",
        "WEBPACK_ASSETS_FUZZY_LOAD_TAG=${webpackAssetsFuzzyTag}",
        "WEBPACK_ASSETS_PREFIX=${env.WEBPACK_ASSETS_PREFIX}",
        "WEBPACK_CACHE_FUZZY_LOAD_TAG=${webpackCacheFuzzyTag}",
        "YARN_RUNNER_PREFIX=${env.YARN_RUNNER_PREFIX}",
        "READ_BUILD_CACHE=${readBuildCache}",
        "WRITE_BUILD_CACHE=0",
      ]) {
        try {
          sh """#!/bin/bash
          set -ex

          build/new-jenkins/docker-build.sh $PATCHSET_TAG$platformSuffix

           $asyncStepsStr
          """
        } catch (e) {
          handleDockerBuildFailure("$PATCHSET_TAG$platformSuffix", e)
        }
      }
    }

    sh "./build/new-jenkins/docker-with-flakey-network-protection.sh push $PATCHSET_TAG$platformSuffix"

    if (configuration.isChangeMerged()) {
      final GIT_REV = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
      sh "docker tag $PATCHSET_TAG$platformSuffix \$BUILD_IMAGE:${GIT_REV}"

      sh "./build/new-jenkins/docker-with-flakey-network-protection.sh push \$BUILD_IMAGE:${GIT_REV}"
    }

    sh(script: """
      ./build/new-jenkins/docker-with-flakey-network-protection.sh push -a $WEBPACK_BUILDER_PREFIX || true
      ./build/new-jenkins/docker-with-flakey-network-protection.sh push -a $YARN_RUNNER_PREFIX || true
      ./build/new-jenkins/docker-with-flakey-network-protection.sh push -a $RUBY_RUNNER_PREFIX || true
      ./build/new-jenkins/docker-with-flakey-network-protection.sh push -a $BASE_RUNNER_PREFIX || true
      ./build/new-jenkins/docker-with-flakey-network-protection.sh push -a $WEBPACK_ASSETS_PREFIX
    """, label: 'upload cache images')
  }
}

def i18nExtract() {
  def dest = 's3://instructure-translations/sources/canvas-lms/en/en.yml'
  def roleARN = 'arn:aws:iam::307761260553:role/translations-jenkins'

  sh(
    label: 'generate the source translations file (en.yml)',
    script: """
      docker run --name=transifreq \
        -e RAILS_LOAD_ALL_LOCALES=1 \
        -e COMPILE_ASSETS_CSS=0 \
        -e COMPILE_ASSETS_STYLEGUIDE=0 \
        -e COMPILE_ASSETS_BRAND_CONFIGS=0 \
        -e COMPILE_ASSETS_BUILD_JS=0 \
        $PATCHSET_TAG \
          bundle exec rake canvas:compile_assets i18n:extract
    """
  )

  sh(
    label: 'stage the source translations file for uploading to s3',
    script: ' \
      docker cp \
        transifreq:/usr/src/app/config/locales/generated/en.yml \
        transifreq-en.yml \
    '
  )

  sh(
    label: 'upload the source translations file to s3',
    script: """
      aws configure set profile.transifreq.credential_source Ec2InstanceMetadata &&
      aws configure set profile.transifreq.role_arn $roleARN &&
      aws s3 cp --profile transifreq --acl bucket-owner-full-control \
        ./transifreq-en.yml \
        $dest
    """
  )
}
