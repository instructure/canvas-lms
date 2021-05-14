/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

def runSuite() {
  withEnv([]) {
    try {
      sh(script: 'docker-compose exec -T -e RSPEC_PROCESSES -e ENABLE_AXE_SELENIUM canvas bash -c \'build/new-jenkins/rspec-with-retries.sh\'', label: 'Run Tests')
    } catch (org.jenkinsci.plugins.workflow.steps.FlowInterruptedException e) {
      if (e.causes[0] instanceof org.jenkinsci.plugins.workflow.steps.TimeoutStepExecution.ExceededTimeout) {
        /* groovylint-disable-next-line GStringExpressionWithinString */
        sh '''#!/bin/bash
          ids=( $(docker ps -aq --filter "name=canvas_") )
          for i in "${ids[@]}"
          do
            docker exec $i bash -c "cat /usr/src/app/log/cmd_output/*.log"
          done
        '''
      }

      throw e
    }
  }
}

return this
