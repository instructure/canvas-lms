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
import {View} from '@canvas/backbone'
import $ from 'jquery'
import template from '../../jst/AssignmentGroupCreateDialog.handlebars'
import '@canvas/jquery/jquery.toJSON'
import '@canvas/jquery/jquery.instructure_forms'
import '@canvas/jquery/jquery.disableWhileLoading'
import '@canvas/rails-flash-notifications'
import '@canvas/util/jquery/fixDialogButtons'

const I18n = useI18nScope('AssignmentGroupCreateDialog')

extend(AssignmentGroupCreateDialog, View)

function AssignmentGroupCreateDialog() {
  this.closeDialog = this.closeDialog.bind(this)
  this.cancel = this.cancel.bind(this)
  this.createAssignmentGroup = this.createAssignmentGroup.bind(this)
  this.render = this.render.bind(this)
  return AssignmentGroupCreateDialog.__super__.constructor.apply(this, arguments)
}

AssignmentGroupCreateDialog.prototype.events = {
  submit: 'createAssignmentGroup',
  'click .cancel-button': 'cancel',
}

AssignmentGroupCreateDialog.prototype.tagName = 'div'

AssignmentGroupCreateDialog.prototype.render = function () {
  this.$el.html(template())
  this.$el
    .dialog({
      title: I18n.t('titles.add_assignment_group', 'Add Assignment Group'),
      width: 'auto',
      modal: true,
      zIndex: 1000,
    })
    .fixDialogButtons()
  this.$el
    .closest('.ui-dialog')
    .find('.ui-dialog-titlebar-close')
    .click(
      (function (_this) {
        return function () {
          return _this.cancel()
        }
      })(this)
    )
  return this
}

AssignmentGroupCreateDialog.prototype.createAssignmentGroup = function (event) {
  event.preventDefault()
  event.stopPropagation()
  const disablingDfd = new $.Deferred()
  this.$el.disableWhileLoading(disablingDfd)
  return $.ajaxJSON(
    '/courses/' + ENV.CONTEXT_ID + '/assignment_groups',
    'POST',
    this.$el.find('form').toJSON(),
    (function (_this) {
      return function (data) {
        disablingDfd.resolve()
        _this.closeDialog()
        return _this.trigger('assignmentGroup:created', data.assignment_group)
      }
    })(this)
  )
}

AssignmentGroupCreateDialog.prototype.cancel = function () {
  this.trigger('assignmentGroup:canceled')
  return this.closeDialog()
}

AssignmentGroupCreateDialog.prototype.closeDialog = function () {
  this.$el.dialog('close')
  return this.trigger('close')
}

export default AssignmentGroupCreateDialog
