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

def setupNode() {
  def refspecToCheckout = env.GERRIT_PROJECT == 'canvas-lms' ? env.JENKINSFILE_REFSPEC : env.CANVAS_LMS_REFSPEC

  checkoutRepo('canvas-lms', refspecToCheckout, 1)

  credentials.withStarlordDockerLogin { ->
    sh "./build/new-jenkins/docker-with-flakey-network-protection.sh pull $KARMA_RUNNER_IMAGE"
  }
}

def tearDownNode() {
  archiveArtifacts artifacts: 'tmp/**/*.xml'
  junit 'tmp/**/*.xml'
}
