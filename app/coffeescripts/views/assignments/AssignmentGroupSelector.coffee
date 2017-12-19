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
  'i18n!assignment'
  'Backbone'
  'underscore'
  'jquery'
  './AssignmentGroupCreateDialog'
  'jst/assignments/AssignmentGroupSelector'
], (I18n, Backbone, _, $, AssignmentGroupCreateDialog, template) ->

  class AssignmentGroupSelector extends Backbone.View

    template: template

    ASSIGNMENT_GROUP_ID = '#assignment_group_id'

    els: do ->
      els = {}
      els["#{ASSIGNMENT_GROUP_ID}"] = '$assignmentGroupId'
      els

    events: do ->
      events = {}
      events["change #{ASSIGNMENT_GROUP_ID}"] = 'showAssignmentGroupCreateDialog'
      events

    @optionProperty 'parentModel'
    @optionProperty 'assignmentGroups'
    @optionProperty 'nested'

    showAssignmentGroupCreateDialog: =>
      if @$assignmentGroupId.val() is 'new'
        @dialog = new AssignmentGroupCreateDialog().render()
        @dialog.on 'assignmentGroup:created', (group) =>
          $newGroup = $('<option>')
          $newGroup.val(group.id)
          $newGroup.text(group.name)
          @$assignmentGroupId.prepend $newGroup
          @$assignmentGroupId.val(group.id)
        @dialog.on 'assignmentGroup:canceled', =>
          @$assignmentGroupId.val(@assignmentGroups[0].id)

    toJSON: =>
      assignmentGroups: @assignmentGroups
      assignmentGroupId: @parentModel.assignmentGroupId()
      frozenAttributes: @parentModel.frozenAttributes()
      nested: @nested
      inClosedGradingPeriod: @parentModel.inClosedGradingPeriod()

    fieldSelectors:
      assignmentGroupSelector: '#assignment_group_id'

    validateBeforeSave: (data, errors) =>
      errors = @_validateAssignmentGroupId data, errors
      errors

    _validateAssignmentGroupId: (data, errors) =>
      agid = if @nested
        data.assignment.assignmentGroupId()
      else
        data.assignment_group_id

      if agid == 'new'
        errors["assignmentGroupSelector"] = [
          message: I18n.t 'assignment_group_must_have_group', 'Please select an assignment group for this assignment'
        ]
      errors
