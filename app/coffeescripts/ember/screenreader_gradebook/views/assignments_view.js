#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'ember'
  'underscore'
  '../../../gradebook/GradebookHeaderMenu'
  '../../../SubmissionDetailsDialog'
], (Ember, _, GradebookHeaderMenu, SubmissionDetailsDialog) ->

  AssignmentsView = Ember.View.extend
    templateName: 'assignments'

    mergeObjects: (old_ag, new_ag) ->
      Ember.setProperties(old_ag, new_ag)

    actions:
      openDialog: (dialogType) ->
        con = @controller
        assignment = con.get('selectedAssignment')
        options =
          assignment: assignment
          students: con.studentsThatCanSeeAssignment(assignment)
          selected_section: con.get('selectedSection')?.id
          context_id: ENV.GRADEBOOK_OPTIONS.context_id
          context_url: ENV.GRADEBOOK_OPTIONS.context_url
          speed_grader_enabled: ENV.GRADEBOOK_OPTIONS.speed_grader_enabled
          change_grade_url: ENV.GRADEBOOK_OPTIONS.change_grade_url
          isAdmin: _.contains(ENV.current_user_roles, 'admin')

        dialogs =
          'assignment_details': GradebookHeaderMenu::showAssignmentDetails
          'message_students': GradebookHeaderMenu::messageStudentsWho
          'set_default_grade': GradebookHeaderMenu::setDefaultGrade
          'curve_grades': GradebookHeaderMenu::curveGrades
          'submission': SubmissionDetailsDialog.open

        switch dialogType
          when 'submission'
            dialogs[dialogType]?.call(this, con.get('selectedAssignment'), con.get('selectedStudent'), options)
          else
            dialogs[dialogType]?.call(this, options)

