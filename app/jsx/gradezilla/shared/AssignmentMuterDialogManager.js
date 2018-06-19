/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import AssignmentMuter from 'compiled/AssignmentMuter'

export default class AssignmentMuterDialogManager {
  constructor(assignment, url, submissionsLoaded, anonymousModeratedMarkingEnabled) {
    this.assignment = assignment
    this.url = url
    this.submissionsLoaded = submissionsLoaded
    this.anonymousModeratedMarkingEnabled = anonymousModeratedMarkingEnabled

    this.showDialog = this.showDialog.bind(this)
    this.isDialogEnabled = this.isDialogEnabled.bind(this)
  }

  showDialog(cb) {
    const assignmentMuter = new AssignmentMuter(null, this.assignment, this.url, null, {
      openDialogInstantly: true
    })
    assignmentMuter.show(cb)
  }

  isDialogEnabled() {
    if (!this.submissionsLoaded) {
      return false
    }

    if (
      this.assignment.muted &&
      this.anonymousModeratedMarkingEnabled &&
      this.assignment.anonymous_grading
    ) {
      return this.assignment.grades_published
    }

    return true
  }
}
