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

def nodeRequirementsTemplate() {
  def baseTestContainer = [
    image: env.LINTERS_RUNNER_IMAGE,
    command: 'cat',
    envVars: [
      GERGICH_DB_PATH: '/home/docker/gergich',
      GERGICH_GIT_PATH: env.DOCKER_WORKDIR,
    ]
  ]

  def containers = ['bundle', 'code', 'feature-flag', 'groovy', 'master-bouncer', 'webpack', 'yarn'].collect { containerName ->
    baseTestContainer + [name: containerName]
  }

  return [
    containers: containers,
    volumes: [
      baseTestContainer.envVars.GERGICH_DB_PATH,
    ]
  ]
}

def tearDownNode() {
  { ->
    container('code') {
      sh './build/new-jenkins/linters/run-gergich-publish.sh'
    }
  }
}

def codeStage(stages) {
  { ->
    def codeEnvVars = [
      "PRIVATE_PLUGINS=${commitMessageFlag('canvas-lms-private-plugins') as String}",
      "SKIP_ESLINT=${commitMessageFlag('skip-eslint') as Boolean}",
    ]

    callableWithDelegate(queueTestStage())(stages,
      name: 'code',
      envVars: codeEnvVars,
      command: './build/new-jenkins/linters/run-gergich-linters.sh'
    )
  }
}

def masterBouncerStage(stages) {
  { ->
    credentials.withMasterBouncerCredentials {
      def masterBouncerEnvVars = [
        'GERGICH_REVIEW_LABEL=Lint-Review',
        "MASTER_BOUNCER_KEY=$MASTER_BOUNCER_KEY",
      ]

      callableWithDelegate(queueTestStage())(stages,
        name: 'master-bouncer',
        envVars: masterBouncerEnvVars,
        required: env.MASTER_BOUNCER_RUN == '1',
        command: 'master_bouncer check'
      )
    }
  }
}

def bundleStage(stages, buildConfig) {
  { ->
    def bundleEnvVars = [
      "PLUGINS_LIST=${commitMessageFlag('canvas-lms-plugins') as String}"
    ]

    callableWithDelegate(queueTestStage())(stages,
      name: 'bundle',
      envVars: bundleEnvVars,
      required: filesChangedStage.hasBundleFiles(buildConfig),
      command: './build/new-jenkins/linters/run-gergich-bundle.sh',
    )
  }
}

def yarnStage(stages, buildConfig) {
  { ->
    def yarnEnvVars = [
      "PLUGINS_LIST=${commitMessageFlag('canvas-lms-plugins') as String}"
    ]

    callableWithDelegate(queueTestStage())(stages,
      name: 'yarn',
      envVars: yarnEnvVars,
      required: env.GERRIT_PROJECT == 'canvas-lms' && filesChangedStage.hasYarnFiles(buildConfig),
      command: './build/new-jenkins/linters/run-gergich-yarn.sh',
    )
  }
}

def groovyStage(stages, buildConfig) {
  { ->
    callableWithDelegate(queueTestStage())(stages,
      name: 'groovy',
      required: env.GERRIT_PROJECT == 'canvas-lms' && filesChangedStage.hasGroovyFiles(buildConfig),
      command: 'npx npm-groovy-lint --path \".\" --ignorepattern \"**/node_modules/**\" --files \"**/*.groovy,**/Jenkinsfile*\" --config \".groovylintrc.json\" --loglevel info --failon warning',
    )
  }
}

def queueTestStage() {
  { opts, stages ->
    extendedStage("Linters - ${opts.name}")
      .envVars(opts.containsKey('envVars') ? opts.envVars : [])
      .hooks(buildSummaryReportHooks.call())
      .nodeRequirements(container: opts.name)
      .required(opts.containsKey('required') ? opts.required : true)
      .queue(stages) {
        sh(opts.command)

        if (commitMessageFlag('force-failure-linters') as Boolean) {
          error 'lintersStage: force failing due to flag'
        }
      }
  }
}
