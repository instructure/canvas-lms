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

import $ from 'jquery'
import I18n from 'i18n!gradebooksharedSetDefaultGradeDialogManager'
import 'compiled/jquery.rails_flash_notifications'

import AsyncComponents from '../default_gradebook/AsyncComponents'

class SetDefaultGradeDialogManager {
  constructor(
    assignment,
    students,
    contextId,
    selectedSection,
    isAdmin = false,
    submissionsLoaded = false
  ) {
    this.assignment = assignment
    this.students = students
    this.contextId = contextId
    this.selectedSection = selectedSection
    this.isAdmin = isAdmin
    this.submissionsLoaded = submissionsLoaded

    this.showDialog = this.showDialog.bind(this)
  }

  getSetDefaultGradeDialogOptions() {
    return {
      assignment: this.assignment,
      students: this.students,
      context_id: this.contextId,
      selected_section: this.selectedSection
    }
  }

  async showDialog(cb) {
    if (this.isAdmin || !this.assignment.inClosedGradingPeriod) {
      const SetDefaultGradeDialog = await AsyncComponents.loadSetDefaultGradeDialog()
      const dialog = new SetDefaultGradeDialog(this.getSetDefaultGradeDialogOptions())

      dialog.show(cb)
    } else {
      $.flashError(
        I18n.t(
          'Unable to set default grade because this ' +
            'assignment is due in a closed grading period for at least one student'
        )
      )
    }
  }

  isDialogEnabled() {
    return this.submissionsLoaded && this.assignment.grades_published
  }
}

export default SetDefaultGradeDialogManager
