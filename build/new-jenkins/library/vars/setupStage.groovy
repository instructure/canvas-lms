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

def call() {
  def refspecToCheckout = env.GERRIT_PROJECT == 'canvas-lms' ? env.GERRIT_REFSPEC : env.CANVAS_LMS_REFSPEC
  checkoutRepo('canvas-lms', refspecToCheckout, 100)

  if (env.GERRIT_PROJECT != 'canvas-lms') {
    dir(env.LOCAL_WORKDIR) {
      checkoutRepo(GERRIT_PROJECT, env.GERRIT_REFSPEC, 2)
    }

    // Plugin builds using the dir step above will create this @tmp file, we need to remove it
    // https://issues.jenkins.io/browse/JENKINS-52750
    sh 'rm -vr gems/plugins/*@tmp'
  }

  gems = configuration.plugins()
  echo "Plugin list: ${gems}"
  def pluginsToPull = []
  gems.each { gem ->
    if (env.GERRIT_PROJECT != gem) {
      pluginsToPull.add([name: gem, version: _getPluginVersion(gem), target: "gems/plugins/$gem"])
    }
  }

  pluginsToPull.add([name: 'qti_migration_tool', version: _getPluginVersion('qti_migration_tool'), target: 'vendor/qti_migration_tool'])

  pullRepos(pluginsToPull)

  libraryScript.load('bash/docker-tag-remote.sh', './build/new-jenkins/docker-tag-remote.sh')
}

def _getPluginVersion(plugin) {
  if (env.GERRIT_BRANCH.contains('stable/')) {
    return configuration.getString("pin-commit-$plugin", env.GERRIT_BRANCH)
  }
  return env.GERRIT_EVENT_TYPE == 'change-merged' ? 'master' : configuration.getString("pin-commit-$plugin", 'master')
}
