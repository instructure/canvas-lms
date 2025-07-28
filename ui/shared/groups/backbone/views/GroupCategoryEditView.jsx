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

import React from 'react'
import ReactDOM from 'react-dom'
import numberHelper from '@canvas/i18n/numberHelper'
import {createRoot} from 'react-dom/client'
import {extend} from '@canvas/backbone/utils'
import {extend as lodashExtend} from 'lodash'
import {useScope as createI18nScope} from '@canvas/i18n'
import DialogFormView from '@canvas/forms/backbone/views/DialogFormView'
import wrapperTemplate from '@canvas/forms/jst/EmptyDialogFormWrapper.handlebars'
import template from '../../jst/groupCategoryEdit.handlebars'
import SelfSignupEndDate from '../../react/CreateOrEditSetModal/SelfSignupEndDate'
import GroupLimitInput from '../../react/GroupLimitInput'
import GroupSetNameInput from '../../react/GroupSetNameInput'

const I18n = createI18nScope('groups')

extend(GroupCategoryEditView, DialogFormView)

function GroupCategoryEditView() {
  this.groupSetNameInputRoot = null
  this.groupLimitInputRoot = null
  this.shouldShowEmptyNameError = false
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

GroupCategoryEditView.prototype.renderGroupLimitInput = function () {
  const groupSetNameInputContainer = document.getElementById(`group_set_${this.model.id}_name_input_container`)
  if (groupSetNameInputContainer) {
    const getShouldShowEmptyNameError = () => this.shouldShowEmptyNameError
    const setShouldShowEmptyNameError = (shouldShow) => { this.shouldShowEmptyNameError = shouldShow }
    const root = this.groupSetNameInputRoot ?? createRoot(groupSetNameInputContainer)
    root.render(
      <GroupSetNameInput
        id={this.model.id}
        initialValue={groupSetNameInputContainer.dataset.value}
        getShouldShowEmptyNameError={getShouldShowEmptyNameError}
        setShouldShowEmptyNameError={setShouldShowEmptyNameError}
      />
    )
  }
  const groupLimitContainer = document.getElementById(`group_limit_input_container_${this.model.id}`)
  if (groupLimitContainer) {
    const root = this.groupLimitInputRoot ?? createRoot(groupLimitContainer)
    root.render(
      <GroupLimitInput initialValue={groupLimitContainer.dataset.value} />
    )
  }
}

GroupCategoryEditView.prototype.onSaveSuccess = function () {
  this.shouldKeepNewDate = true
  GroupCategoryEditView.__super__.onSaveSuccess.apply(this, arguments)
}

GroupCategoryEditView.prototype.close = function (event) {
  // reset self sign up end date
  if (!this.shouldKeepNewDate) {
    const initialEndDate = this.model.get('initial_self_signup_end_at')
    this.model.set('self_signup_end_at', initialEndDate)
  }
  return GroupCategoryEditView.__super__.close.apply(this, arguments)
}

GroupCategoryEditView.prototype.afterRender = function () {
  this.renderGroupLimitInput()
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

GroupCategoryEditView.prototype.showSelfSignupEndDatePicker = function () {
  const container = document.getElementById(`category_${this.model.id}_self_signup_end_at_picker`)
  if (container) {
    const root = createRoot(container)
    const initialEndDate = this.model.get('self_signup_end_at')
    this.model.set('initial_self_signup_end_at', initialEndDate)
    const updateEndDate = end => {
      this.model.set('self_signup_end_at', end)
    }
    root.render(<SelfSignupEndDate initialEndDate={initialEndDate} onDateChange={updateEndDate} />)
  }
}

GroupCategoryEditView.prototype.toggleSelfSignup = function () {
  const disabled = !this.$selfSignupToggle.prop('checked')
  this.$selfSignupControls.css({
    opacity: disabled ? 0.5 : 1,
  })
  if (ENV.self_signup_deadline_enabled) {
    this.showSelfSignupEndDatePicker()
  }
  return this.$selfSignupControls.find(':input').prop('disabled', disabled)
}

GroupCategoryEditView.prototype.validateFormData = function (data, _errors) {
  const errors = {}
  if (!data.name) {
    this.shouldShowEmptyNameError = true
    errors.name = [
      {
        message: I18n.t('group_set_name_required', 'Name is required')
      },
    ]
  } else {
    if (data.name.length > 255) {
      errors.name = [
        {
          message: I18n.t('group_set_name_length', 'Name must be 255 characters or less')
        },
      ]
    }
  }

  if (data.group_limit != null && data.group_limit !== '') {
    const groupLimitValue = Number(data.group_limit)
    if (Number.isNaN(groupLimitValue) || !Number.isInteger(groupLimitValue)) {
      errors.group_limit = [
        {
          message: I18n.t('group_limit_number', 'Value must be a whole number'),
        },
      ]
    } else if (numberHelper.parse(groupLimitValue) < 2) {
      errors.group_limit = [
        {
          message: I18n.t('group_limit_min', 'Value must be greater than or equal to 2'),
        },
      ]
    }
  }

  return errors
}

GroupCategoryEditView.prototype.showErrors = function (errors) {
  if (errors.name) {
    document.getElementById(`category_${this.model.id}_name`)?.focus()
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
      restrict_self_signup: json.self_signup === 'restricted'
    },
  )
}

export default GroupCategoryEditView
