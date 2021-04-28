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

@Field static COMMIT_HISTORY = 100

@Field static CHANGED_FILES = [
  'Jenkinsfile*',
  '^docker-compose.new-jenkins*.yml',
  'build/new-jenkins/*'
]

def call() {
  def branch = env.GERRIT_BRANCH
  _rebase(branch, COMMIT_HISTORY)
  if ( branch ==~ /dev\/.*/ ) {
    _rebase('master', commitHistory)
  }

  if (!env.JOB_NAME.endsWith('Jenkinsfile') && git.changedFiles(CHANGED_FILES, 'origin/master')) {
    error 'Jenkinsfile has been updated. Please retrigger your patchset for the latest updates.'
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