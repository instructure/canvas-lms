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

private def runLinterCommand(String stageName, Closure scriptBlock) {
  def startTime = System.currentTimeMillis()
  try {
    scriptBlock()
  } finally {
    buildSummaryReport.trackStage(stageName, startTime)
  }
}

def provisionDocker() {
  // Pull the linters image from registry and tag it locally
  credentials.withStarlordCredentials {
    sh """
      set -ex

      ./build/new-jenkins/docker-with-flakey-network-protection.sh pull $LINTERS_RUNNER_IMAGE
      docker tag $LINTERS_RUNNER_IMAGE local/linters-runner
      echo "Linters runner image pulled and tagged locally."
    """
  }
}

def runLintersInline() {
  def hasBundleFiles = env.HAS_BUNDLE_FILES == 'true'
  def hasYarnFiles = env.HAS_YARN_FILES == 'true'
  def hasJsFiles = env.HAS_JS_FILES == 'true'
  def hasGraphqlFiles = env.HAS_GRAPHQL_FILES == 'true'
  def hasGroovyFiles = env.HAS_GROOVY_FILES == 'true'
  def isMerged = configuration.isChangeMerged()

  withEnv([
    "COMPOSE_FILE=docker-compose.new-jenkins-linters.yml",
    "GERGICH_REVIEW_LABEL=Lint-Review",
    "GERGICH_GIT_PATH=${pipelineHelpers.getDockerWorkDir()}"
  ]) {
    // Run all linter stages in parallel
    def linterStages = [:]

    // Pre-merge linters (only run on unmerged changes)
    if (!isMerged) {
      linterStages['Linters - Gergich'] = {
        runGergichLinters()
      }

      if (hasBundleFiles) {
        linterStages['Linters - Bundle Check'] = {
          runBundleCheck()
        }
      }

      if (env.GERRIT_PROJECT == 'canvas-lms' && hasYarnFiles) {
        linterStages['Linters - Yarn Check'] = {
          runYarnCheck()
        }
      }

      if (hasYarnFiles || hasJsFiles) {
        linterStages['Linters - Misc JS Checks'] = {
          runMiscJsChecks()
        }

        linterStages['Linters - ESLint'] = {
          runEslint()
        }
      }

      if (env.GERRIT_PROJECT == 'canvas-lms' && hasJsFiles) {
        linterStages['Linters - Biome'] = {
          runBiome()
        }
      }

      if (env.GERRIT_PROJECT == 'canvas-lms' && (hasJsFiles || hasGraphqlFiles || hasYarnFiles)) {
        linterStages['Linters - TypeScript'] = {
          runTypeScript()
        }
      }

      if (env.GERRIT_PROJECT == 'canvas-lms' && hasGraphqlFiles) {
        linterStages['Linters - GraphQL Schema'] = {
          runGraphqlSchema()
        }
      }

      if (env.GERRIT_PROJECT == 'canvas-lms' && hasGroovyFiles) {
        linterStages['Linters - Groovy'] = {
          runGroovyLint()
        }
      }

      if (env.MASTER_BOUNCER_RUN == '1') {
        linterStages['Linters - Master Bouncer'] = {
          runMasterBouncer()
        }
      }
    }

    // Post-merge security scan (only run on merged builds)
    if (isMerged) {
      linterStages['Linters - Snyk Security Scan'] = {
        runSnykScan()
      }
    }

    parallel(linterStages)

    // Publish Gergich results after all linters complete (pre-merge only)
    if (!isMerged) {
      publishGergichResults()
    }

    // Check for force failure
    if (commitMessageFlag('force-failure-linters') as Boolean) {
      error 'Linters: force failing due to [force-failure-linters] flag'
    }
  }
}

def runGergichLinters() {
  runLinterCommand('Linters - Gergich') {
    withEnv(["PRIVATE_PLUGINS=${commitMessageFlag('canvas-lms-private-plugins') as String}"]) {
      sh '''
        set -ex
        docker compose run --rm linters ./build/new-jenkins/linters/run-gergich-linters.sh
      '''
    }
  }
}

def runBundleCheck() {
  runLinterCommand('Linters - Bundle Check') {
    withEnv(["PLUGINS_LIST=${commitMessageFlag('canvas-lms-plugins') as String}"]) {
      sh '''
        set -ex
        docker compose run --rm linters ./build/new-jenkins/linters/run-gergich-bundle.sh
      '''
    }
  }
}

def runYarnCheck() {
  runLinterCommand('Linters - Yarn Check') {
    withEnv(["PLUGINS_LIST=${commitMessageFlag('canvas-lms-plugins') as String}"]) {
      sh '''
        set -ex
        docker compose run --rm linters ./build/new-jenkins/linters/run-gergich-yarn.sh
      '''
    }
  }
}

def runMiscJsChecks() {
  runLinterCommand('Linters - Misc JS Checks') {
    sh '''
      set -ex
      docker compose run --rm linters ./build/new-jenkins/linters/run-misc-js-checks.sh
    '''
  }
}

def runEslint() {
  runLinterCommand('Linters - ESLint') {
    withEnv(["SKIP_ESLINT=${commitMessageFlag('skip-eslint') as Boolean}"]) {
      sh '''
        set -ex
        docker compose run --rm linters ./build/new-jenkins/linters/run-eslint.sh
      '''
    }
  }
}

def runBiome() {
  runLinterCommand('Linters - Biome') {
    withEnv(["SKIP_BIOME=${commitMessageFlag('skip-biome') as Boolean}"]) {
      sh '''
        set -ex
        docker compose run --rm linters ./build/new-jenkins/linters/run-gergich-biome.sh
      '''
    }
  }
}

def runTypeScript() {
  runLinterCommand('Linters - TypeScript') {
    sh '''
      set -ex
      docker compose run --rm linters ./build/new-jenkins/linters/run-ts-type-check.sh
    '''
  }
}

def runGraphqlSchema() {
  runLinterCommand('Linters - GraphQL Schema') {
    sh '''
      set -ex
      docker compose run --rm linters ./build/new-jenkins/linters/run-gergich-graphql-schema.sh
    '''
  }
}

def runGroovyLint() {
  runLinterCommand('Linters - Groovy') {
    sh '''
      set -ex
      docker compose run --rm linters \
        npx npm-groovy-lint \
          --path "." \
          --ignorepattern "**/node_modules/**" \
          --files "**/*.groovy,**/Jenkinsfile*" \
          --config ".groovylintrc.json" \
          --loglevel info \
          --failon warning
    '''
  }
}

def runMasterBouncer() {
  runLinterCommand('Linters - Master Bouncer') {
    credentials.withMasterBouncerCredentials {
      sh '''
        set -ex
        docker compose run --rm \
          -e MASTER_BOUNCER_KEY=$MASTER_BOUNCER_KEY \
          -e GERRIT_HOST=$GERRIT_HOST \
          linters master_bouncer check
      '''
    }
  }
}

def runSnykScan() {
  runLinterCommand('Linters - Snyk Security Scan') {
    credentials.withSnykCredentials {
      sh '''
        set -ex
        docker compose run --rm \
          -e SNYK_TOKEN=$SNYK_TOKEN \
          linters ./build/new-jenkins/linters/run-snyk.sh
      '''
    }
  }
}

def publishGergichResults() {
  runLinterCommand('Linters - Publish Gergich Results') {
    sh '''
      set -ex
      docker compose run --rm linters ./build/new-jenkins/linters/run-gergich-publish.sh
    '''
  }
}

return this
