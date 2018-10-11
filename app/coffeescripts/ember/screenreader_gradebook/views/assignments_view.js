//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import Ember from 'ember'
import _ from 'underscore'
import GradebookHeaderMenu from '../../../gradebook/GradebookHeaderMenu'
import SubmissionDetailsDialog from '../../../SubmissionDetailsDialog'

const AssignmentsView = Ember.View.extend({
  templateName: 'assignments',

  mergeObjects(old_ag, new_ag) {
    return Ember.setProperties(old_ag, new_ag)
  },

  actions: {
    openDialog(dialogType) {
      const con = this.controller
      const assignment = con.get('selectedAssignment')
      const options = {
        assignment,
        students: con.studentsThatCanSeeAssignment(assignment),
        selected_section: __guard__(con.get('selectedSection'), x => x.id),
        context_id: ENV.GRADEBOOK_OPTIONS.context_id,
        context_url: ENV.GRADEBOOK_OPTIONS.context_url,
        speed_grader_enabled: ENV.GRADEBOOK_OPTIONS.speed_grader_enabled,
        change_grade_url: ENV.GRADEBOOK_OPTIONS.change_grade_url,
        isAdmin: _.contains(ENV.current_user_roles, 'admin')
      }

      const dialogs = {
        assignment_details: GradebookHeaderMenu.prototype.showAssignmentDetails,
        message_students: GradebookHeaderMenu.prototype.messageStudentsWho,
        set_default_grade: GradebookHeaderMenu.prototype.setDefaultGrade,
        curve_grades: GradebookHeaderMenu.prototype.curveGrades,
        submission: SubmissionDetailsDialog.open
      }

      switch (dialogType) {
        case 'submission':
          return dialogs[dialogType] != null
            ? dialogs[dialogType].call(
                this,
                con.get('selectedAssignment'),
                con.get('selectedStudent'),
                options
              )
            : undefined
        default:
          return dialogs[dialogType] != null ? dialogs[dialogType].call(this, options) : undefined
      }
    }
  }
})

export default AssignmentsView

function __guard__(value, transform) {
  return typeof value !== 'undefined' && value !== null ? transform(value) : undefined
}
