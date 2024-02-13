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
  def basePactContainer = [
    image: env.PATCHSET_TAG,
    command: 'cat',
    ttyEnabled: true,
    resourceRequestCpu: '1',
    resourceLimitCpu: '8',
    envVars: [
      DISABLE_SPRING: 'true',
      ENCRYPTION_KEY: 'facdd3a131ddd8988b14f6e4e01039c93cfa0160',
      PACT_BROKER_HOST: 'inst-pact-broker.inseng.net',
      PACT_BROKER_USERNAME: env.PACT_BROKER_USERNAME,
      PACT_BROKER_PASSWORD: env.PACT_BROKER_PASSWORD,
      PACT_BROKER_PROTOCOL: 'https',
      POSTGRES_PASSWORD: env.POSTGRES_PASSWORD,
      RAILS_ENV: 'test',
      RANDOMIZE_SEQUENCES: 1,
    ]
  ]

  return [
    containers: [
      basePactContainer + [name: 'pact_test1'],
      basePactContainer + [name: 'pact_test2'],
      basePactContainer + [name: 'pact_test3'],
      basePactContainer + [name: 'pact_test4'],
      basePactContainer + [name: 'pact_test5'],
      basePactContainer + [name: 'pact_test6'],
      [
        name: 'postgres',
        image: env.POSTGRES_IMAGE_TAG,
        ttyEnabled: true,
        resourceRequestCpu: '1',
        resourceLimitCpu: '8',
        envVars: [
          PGDATA: '/data',
          POSTGRES_PASSWORD: env.POSTGRES_PASSWORD,
        ],
        ports: [5432],
      ],
      [
        name: 'dynamodb',
        image: env.DYNAMODB_IMAGE_TAG,
        resourceRequestCpu: '1',
        resourceLimitCpu: '8',
        ports: [8000],
      ]
    ],
  ]
}

def setupNode() {
  { ->
    container('postgres') {
      sh "createdb -U postgres -T canvas_test ${env.DATABASE_NAME}"
    }
  }
}

def tearDownNode() {
  { ->
    copyToWorkspace srcBaseDir: '/usr/src/app', path: 'log/results'
    junit 'log/results/**/*.xml'
  }
}

def queueTestStage(stageName) {
  { opts, stages ->
    def baseEnvVars = [
      "DATABASE_NAME=${opts.databaseName}",
      "DATABASE_URL=postgres://postgres:${env.POSTGRES_PASSWORD}@postgres:5432/${opts.databaseName}",
      "PACT_API_CONSUMER=${opts.containsKey('consumerName') ? opts.consumerName : ''}",
    ]

    def additionalEnvVars = opts.containsKey('envVars') ? opts.envVars : []

    extendedStage(stageName)
      .envVars(baseEnvVars + additionalEnvVars)
      .hooks([onNodeAcquired: this.setupNode(), onNodeReleasing: this.tearDownNode()])
      .obeysAllowStages(false)
      .nodeRequirements(container: opts.databaseName)
      .queue(stages) { sh(opts.command) }
  }
}

return this
