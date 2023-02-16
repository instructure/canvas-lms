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

import groovy.transform.Field

@Field final static COMMIT_HISTORY = 100

@Field final static CHANGED_FILES = [
  'Jenkinsfile*',
  '^docker-compose.new-jenkins*.yml',
  'build/new-jenkins/*'
]

def call() {
  def branch = env.GERRIT_BRANCH
  _rebase(branch, COMMIT_HISTORY)
  if ( branch ==~ /dev\/.*/ ) {
    _rebase('master', COMMIT_HISTORY)
  }

  if (env.ALLOW_JENKINSFILE_CHANGES != "1" && git.changedFiles(CHANGED_FILES, 'origin/master')) {
    error '''
    Jenkinsfile is different from the expected version and changes are not allowed in the currently running job.

    You are seeing this error because one of the following:
    1. You got unlucky and someone merged a Jenkinsfile change between when the build started and the rebase happened. You
        should re-trigger your PS in this case.
    2. A parent patchset has a change which will cause it to be built with the -Jenkinsfile job. You can bypass this error
        by adding a no-op change to Jenkinsfile that will force this PS to use the local version of the build scripts. If
        you do this, you will need to rebase your PS to keep the build scripts up-to-date manually.
    '''
  }
}

def _rebase(String branch, Integer commitHistory) {
  git.fetch(branch, commitHistory)
  if (!git.hasCommonAncestor(branch)) {
    error "Error: your branch is over ${commitHistory} commits behind ${branch}, please rebase your branch manually."
  }
  if (!git.rebase(branch)) {
    error "Error: Rebase couldn't resolve changes automatically, please resolve these conflicts locally."
  }
}
