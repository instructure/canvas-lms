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
import {createRoot} from 'react-dom/client'
import {extend} from '@canvas/backbone/utils'
import $ from 'jquery'
import {useScope as createI18nScope} from '@canvas/i18n'
import round from '@canvas/round'
import numberHelper from '@canvas/i18n/numberHelper'
import {each, some, extend as lodashExtend} from 'lodash'
import DialogFormView, {getResponsiveWidth} from '@canvas/forms/backbone/views/DialogFormView'
import wrapper from '@canvas/forms/jst/EmptyDialogFormWrapper.handlebars'
import assignmentSettingsTemplate from '../../jst/AssignmentSettings.handlebars'
import {IconWarningSolid} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'

const I18n = createI18nScope('AssignmentSettingsView')

extend(AssignmentSettingsView, DialogFormView)

function AssignmentSettingsView() {
  this.errorRoots = {}
  this.ariaLabels = {}
  return AssignmentSettingsView.__super__.constructor.apply(this, arguments)
}

AssignmentSettingsView.prototype.template = assignmentSettingsTemplate

AssignmentSettingsView.prototype.wrapperTemplate = wrapper

AssignmentSettingsView.prototype.defaults = {
  width: getResponsiveWidth(320, 450),
  height: 500,
  collapsedHeight: 300,
}

AssignmentSettingsView.prototype.events = lodashExtend(
  {},
  AssignmentSettingsView.prototype.events,
  {
    'click .dialog_closer': 'cancel',
    'click #apply_assignment_group_weights': 'toggleTableByClick',
    'keyup .group_weight_value': 'updateTotalWeight',
    'click #assignment_groups_weights button': 'updateTotalWeight'
  },
)

AssignmentSettingsView.optionProperty('assignmentGroups')

AssignmentSettingsView.optionProperty('weightsView')

AssignmentSettingsView.optionProperty('userIsAdmin')

AssignmentSettingsView.prototype.initialize = function () {
  AssignmentSettingsView.__super__.initialize.apply(this, arguments)
  return (this.weights = [])
}

AssignmentSettingsView.prototype.validateFormData = function () {
  const errors = {}
  let shouldFocus = true
  const weightInputs = document.querySelectorAll('.group_weight_value')
  weightInputs.forEach((input) => {
    if (input.value && isNaN(numberHelper.parse(input.value))) {
      errors[input.id] = [{
        type: 'number',
        message: I18n.t('Must be a valid number '),
      }]
      if (shouldFocus) {
        input.focus()
        shouldFocus = false
      }
    }
  })
  return errors
}

AssignmentSettingsView.prototype.openAgain = function () {
  AssignmentSettingsView.__super__.openAgain.apply(this, arguments)
  this.toggleTableByModel()
  return this.addAssignmentGroups()
}

AssignmentSettingsView.prototype.canChangeWeights = function () {
  return (
    this.userIsAdmin ||
    !some(this.assignmentGroups.models, function (ag) {
      return ag.anyAssignmentInClosedGradingPeriod()
    })
  )
}

AssignmentSettingsView.prototype.submit = function (event) {
  if (this.canChangeWeights()) {
    return AssignmentSettingsView.__super__.submit.call(this, event)
  } else {
    return event != null ? event.preventDefault() : void 0
  }
}

AssignmentSettingsView.prototype.saveFormData = function (data) {
  if (data == null) {
    data = null
  }
  const ref = this.weights
  for (let i = 0, len = ref.length; i < len; i++) {
    const v = ref[i]
    const new_weight = v.findWeight()
    v.model.set('group_weight', new_weight)
    v.model.save()
  }
  return AssignmentSettingsView.__super__.saveFormData.call(this, data)
}

AssignmentSettingsView.prototype.cancel = function () {
  if (this.canChangeWeights()) {
    return this.close()
  }
}

AssignmentSettingsView.prototype.onSaveSuccess = function () {
  AssignmentSettingsView.__super__.onSaveSuccess.apply(this, arguments)
  this.assignmentGroups.trigger('change:groupWeights')
  const checked = this.model.get('apply_assignment_group_weights')
  return this.trigger('weightedToggle', checked)
}

AssignmentSettingsView.prototype.toggleTableByModel = function () {
  const checked = this.model.get('apply_assignment_group_weights')
  return this.toggleWeightsTable(checked)
}

AssignmentSettingsView.prototype.toggleTableByClick = function (e) {
  if (this.canChangeWeights()) {
    const checked = $(e.currentTarget).is(':checked')
    return this.toggleWeightsTable(checked)
  } else {
    return e.preventDefault()
  }
}

AssignmentSettingsView.prototype.toggleWeightsTable = function (show) {
  if (show) {
    this.$('#ag_weights_wrapper').show()
    this.$('#apply_assignment_group_weights').prop('checked', true)
    return this.setDimensions(null, this.defaults.height)
  } else {
    this.$('#ag_weights_wrapper').hide()
    this.$('#apply_assignment_group_weights').prop('checked', false)
    return this.setDimensions(null, this.defaults.collapsedHeight)
  }
}

AssignmentSettingsView.prototype.addAssignmentGroups = function () {
  this.clearWeights()
  const canChangeWeights = this.canChangeWeights()
  let total_weight = 0
  const ref = this.assignmentGroups.models
  for (let i = 0, len = ref.length; i < len; i++) {
    const model = ref[i]

    const v = new this.weightsView({
      model,
      canChangeWeights,
    })
    v.render()
    this.$el.find('#assignment_groups_weights tbody').append(v.el)
    this.weights.push(v)
    total_weight += model.get('group_weight') || 0
  }
  total_weight = round(total_weight, 2)
  return this.$el.find('#percent_total').text(
    I18n.n(total_weight, {
      percentage: true,
    }),
  )
}

AssignmentSettingsView.prototype.clearWeights = function () {
  this.weights = []
  return this.$el.find('#assignment_groups_weights tbody').empty()
}

AssignmentSettingsView.prototype.updateTotalWeight = function (event) {
  const groupId = event.currentTarget.getAttribute('groupId')
  if (this.errorRoots[groupId] && event.key !== 'Enter') {
    this.hideErrors(groupId)
  }
  let i, len, total_weight, v
  total_weight = 0
  const ref = this.weights
  for (i = 0, len = ref.length; i < len; i++) {
    v = ref[i]
    total_weight += v.findWeight() || 0
  }
  total_weight = round(total_weight, 2)
  return this.$el.find('#percent_total').text(
    I18n.n(total_weight, {
      percentage: true,
    }),
  )
}

AssignmentSettingsView.prototype.toJSON = function () {
  const data = AssignmentSettingsView.__super__.toJSON.apply(this, arguments)
  data.canChangeWeights = this.canChangeWeights()
  return data
}

export default AssignmentSettingsView
