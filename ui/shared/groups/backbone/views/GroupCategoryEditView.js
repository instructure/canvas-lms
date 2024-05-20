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
import {extend as lodashExtend} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import DialogFormView from '@canvas/forms/backbone/views/DialogFormView'
import wrapperTemplate from '@canvas/forms/jst/EmptyDialogFormWrapper.handlebars'
import template from '../../jst/groupCategoryEdit.handlebars'
import h from '@instructure/html-escape'

const I18n = useI18nScope('groups')

extend(GroupCategoryEditView, DialogFormView)

function GroupCategoryEditView() {
  return GroupCategoryEditView.__super__.constructor.apply(this, arguments)
}

GroupCategoryEditView.prototype.template = template

GroupCategoryEditView.prototype.wrapperTemplate = wrapperTemplate

GroupCategoryEditView.prototype.className = 'form-dialog group-category-edit'

GroupCategoryEditView.prototype.defaults = {
  width: 500,
  height: ENV.allow_self_signup ? 520 : 210,
  title: I18n.t('edit_group_set', 'Edit Group Set'),
  fixDialogButtons: false,
}

GroupCategoryEditView.prototype.els = {
  '.self-signup-help': '$selfSignupHelp',
  '.self-signup-description': '$selfSignup',
  '.self-signup-toggle': '$selfSignupToggle',
  '.self-signup-controls': '$selfSignupControls',
  '.auto-group-leader-toggle': '$autoGroupLeaderToggle',
  '.auto-group-leader-controls': '$autoGroupLeaderControls',
}

GroupCategoryEditView.prototype.events = lodashExtend({}, DialogFormView.prototype.events, {
  'click .dialog_closer': 'close',
  'click .self-signup-toggle': 'toggleSelfSignup',
  'click .auto-group-leader-toggle': 'toggleAutoGroupLeader',
})

GroupCategoryEditView.prototype.afterRender = function () {
  this.toggleSelfSignup()
  this.toggleAutoGroupLeader()
  return this.setAutoLeadershipFormState()
}

GroupCategoryEditView.prototype.openAgain = function () {
  GroupCategoryEditView.__super__.openAgain.apply(this, arguments)
  // reset the form contents
  return this.render()
}

GroupCategoryEditView.prototype.setAutoLeadershipFormState = function () {
  if (this.model.get('auto_leader') != null) {
    this.$autoGroupLeaderToggle.prop('checked', true)
    this.$autoGroupLeaderControls
      .find("input[value='" + this.model.get('auto_leader').toUpperCase() + "']")
      .prop('checked', true)
  } else {
    this.$autoGroupLeaderToggle.prop('checked', false)
  }
  return this.toggleAutoGroupLeader()
}

GroupCategoryEditView.prototype.toggleAutoGroupLeader = function () {
  const enabled = this.$autoGroupLeaderToggle.prop('checked')
  this.$autoGroupLeaderControls.find('label.radio').css({
    opacity: enabled ? 1 : 0.5,
  })
  return this.$autoGroupLeaderControls
    .find('input[name=auto_leader_type]')
    .prop('disabled', !enabled)
}

GroupCategoryEditView.prototype.toggleSelfSignup = function () {
  const disabled = !this.$selfSignupToggle.prop('checked')
  this.$selfSignupControls.css({
    opacity: disabled ? 0.5 : 1,
  })
  return this.$selfSignupControls.find(':input').prop('disabled', disabled)
}

GroupCategoryEditView.prototype.validateFormData = function (_data, _errors) {
  const groupLimit = this.$('[name=group_limit]')
  if (groupLimit.length && !groupLimit[0].validity.valid) {
    return {
      group_limit: [
        {
          message: I18n.t('group_limit_number', 'Group limit must be a number'),
        },
      ],
    }
  }
}

GroupCategoryEditView.prototype.toJSON = function () {
  const json = this.model.present()
  let ref
  return lodashExtend(
    {},
    {
      ENV,
    },
    json,
    {
      enable_self_signup: json.self_signup,
      restrict_self_signup: json.self_signup === 'restricted',
      group_limit:
        '<input name="group_limit"\n        type="number"\n        min="2"\n        class="input-micro"\n        value="' +
        h((ref = json.group_limit) != null ? ref : '') +
        '">',
    }
  )
}

export default GroupCategoryEditView
