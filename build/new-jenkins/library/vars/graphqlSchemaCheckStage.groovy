/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
    command: 'cat'
  ]

  return [
    containers: [baseTestContainer + [name: 'graphql-schema-check']]
  ]
}

def queueTestStage() {
  { ->
    withCredentials([string(credentialsId: 'apollo-key', variable: 'APOLLO_KEY')]) {
      try {
        // Because this gets run inside a Docker container, we can't return the status, as it gets interpreted
        // by our custom Docker execution library as being part of the shell command.
        sh """
        RAILS_ENV=test bundle exec rake graphql:schema
        yarn rover subgraph check ${configuration.apolloGraphRef()} --name ${configuration.apolloSubgraphName()} --schema ${configuration.apolloSchemaPath()}
        """
      } catch (Exception e) {
        // For now, if the schema check fails, simply alert the interop team, rather than fail the build.
        // We're only collecting information for now.
        def extra = 'The preceding patchset failed the GraphQL Post-Merge Schema Check. Please review the schema check to determine if this was a false positive or if the author needs to amend their changes. Note that a link to the schema check within Apollo Studio is output by Rover.'
        slackHelpers.sendSlackFailureWithMsg('#interop-alerts', extra, false)
      }
    }
  }
}
