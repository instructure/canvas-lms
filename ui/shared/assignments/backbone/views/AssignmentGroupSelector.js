/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {extend} from '@canvas/backbone/utils'
import {useScope as useI18nScope} from '@canvas/i18n'
import Backbone from '@canvas/backbone'
import $ from 'jquery'
import AssignmentGroupCreateDialog from './AssignmentGroupCreateDialog'
import template from '../../jst/AssignmentGroupSelector.handlebars'

const I18n = useI18nScope('assignment_group_selector')

const ASSIGNMENT_GROUP_ID = '#assignment_group_id'

extend(AssignmentGroupSelector, Backbone.View)

function AssignmentGroupSelector() {
  this._validateAssignmentGroupId = this._validateAssignmentGroupId.bind(this)
  this.validateBeforeSave = this.validateBeforeSave.bind(this)
  this.toJSON = this.toJSON.bind(this)
  this.showAssignmentGroupCreateDialog = this.showAssignmentGroupCreateDialog.bind(this)
  return AssignmentGroupSelector.__super__.constructor.apply(this, arguments)
}

AssignmentGroupSelector.prototype.template = template

AssignmentGroupSelector.prototype.els = (function () {
  const els = {}
  els['' + ASSIGNMENT_GROUP_ID] = '$assignmentGroupId'
  return els
})()

AssignmentGroupSelector.prototype.events = (function () {
  const events = {}
  events['change ' + ASSIGNMENT_GROUP_ID] = 'showAssignmentGroupCreateDialog'
  return events
})()

AssignmentGroupSelector.optionProperty('parentModel')

AssignmentGroupSelector.optionProperty('assignmentGroups')

AssignmentGroupSelector.optionProperty('nested')

AssignmentGroupSelector.prototype.showAssignmentGroupCreateDialog = function () {
  if (this.$assignmentGroupId.val() === 'new') {
    this.dialog = new AssignmentGroupCreateDialog().render()
    this.dialog.on(
      'assignmentGroup:created',
      (function (_this) {
        return function (group) {
          const $newGroup = $('<option>')
          $newGroup.val(group.id)
          $newGroup.text(group.name)
          _this.$assignmentGroupId.prepend($newGroup)
          return _this.$assignmentGroupId.val(group.id)
        }
      })(this)
    )
    return this.dialog.on(
      'assignmentGroup:canceled',
      (function (_this) {
        return function () {
          return _this.$assignmentGroupId.val(_this.assignmentGroups[0].id)
        }
      })(this)
    )
  }
}

AssignmentGroupSelector.prototype.toJSON = function () {
  return {
    assignmentGroups: this.assignmentGroups,
    assignmentGroupId: this.parentModel.assignmentGroupId(),
    frozenAttributes: this.parentModel.frozenAttributes(),
    nested: this.nested,
    inClosedGradingPeriod: this.parentModel.inClosedGradingPeriod(),
  }
}

AssignmentGroupSelector.prototype.fieldSelectors = {
  assignmentGroupSelector: '#assignment_group_id',
}

AssignmentGroupSelector.prototype.validateBeforeSave = function (data, errors) {
  errors = this._validateAssignmentGroupId(data, errors)
  return errors
}

AssignmentGroupSelector.prototype._validateAssignmentGroupId = function (data, errors) {
  const agid = this.nested ? data.assignment.assignmentGroupId() : data.assignment_group_id
  if (agid === 'new') {
    errors.assignmentGroupSelector = [
      {
        message: I18n.t(
          'assignment_group_must_have_group',
          'Please select an assignment group for this assignment'
        ),
      },
    ]
  }
  return errors
}

export default AssignmentGroupSelector
