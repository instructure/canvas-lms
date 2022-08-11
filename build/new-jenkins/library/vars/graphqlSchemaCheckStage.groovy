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

@groovy.transform.Field final static SCHEMA_CHECK_CONTAINER_NAME = 'rover'

def call() {
  withCredentials([string(credentialsId: 'apollo-key', variable: 'APOLLO_KEY'),
      usernamePassword(
        credentialsId: 'starlord',
        usernameVariable: 'STARLORD_USERNAME',
        passwordVariable: 'STARLORD_PASSWORD'
    )]) {
    sh """
    ./build/new-jenkins/docker-with-flakey-network-protection.sh pull ${configuration.apolloImageName()}
    """

    // Unfortunately, I don't know of a way to get the Apollo Key into the container without passing it as an env var. Jenkins *should* notice we're
    // string interpolating a secret and omit it from the logs, but it's definitely not ideal.
    def status = sh(returnStatus: true, script: """
    docker run -t -v $WORKSPACE/${configuration.apolloSchemaPath()}:/usr/src/app/${configuration.apolloSchemaPath()} -e APOLLO_KEY=${APOLLO_KEY}  ${configuration.apolloImageName()} bash -lc "rover subgraph check ${configuration.apolloGraphRef()} --name ${configuration.apolloSubgraphName()} --schema /usr/src/app/${configuration.apolloSchemaPath()}"
    """)

    if (status != 0) {
      def extra = 'The preceding patchset failed the GraphQL Post-Merge Schema Check. Please review the schema check to determine if this was a false positive or if the author needs to amend their changes. Note that a link to the schema check within Apollo Studio is output by Rover.'
      slackHelpers.sendSlackFailureWithMsg('#interop-alerts', extra, false)
    }
  }
}

def shouldRun() {
  return (configuration.isChangeMerged() && filesChangedStage.hasGraphqlFiles()) || configuration.apolloForceGraphqlSchemaCheck()
}
