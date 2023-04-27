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
import Backbone from '@canvas/backbone'
import template from '../../../jst/subviews/QuestionBank.handlebars'

extend(QuestionBankView, Backbone.View)

function QuestionBankView() {
  this.updateNewQuestionName = this.updateNewQuestionName.bind(this)
  return QuestionBankView.__super__.constructor.apply(this, arguments)
}

QuestionBankView.prototype.template = template

QuestionBankView.optionProperty('questionBanks')

QuestionBankView.optionProperty('disabled_message')

QuestionBankView.prototype.els = {
  '.questionBank': '$questionBankSelect',
  '#createQuestionInput': '$createQuestionInput',
  '#questionBankDisabledMsg': '$questionBankDisabledMsg',
}

QuestionBankView.prototype.events = {
  'change .questionBank': 'setQuestionBankValues',
  'keyup #createQuestionInput': 'updateNewQuestionName',
}

QuestionBankView.prototype.initialize = function (options) {
  options.is_disabled = false
  return QuestionBankView.__super__.initialize.apply(this, arguments)
}

QuestionBankView.prototype.updateNewQuestionName = function (_event) {
  return this.setQbName()
}

QuestionBankView.prototype.setQuestionBankValues = function (event) {
  if (event.target.value === 'new_question_bank') {
    this.$createQuestionInput.show()
    // Ensure focus is on the new input field
    this.$createQuestionInput.focus()
    return this.setQbName()
  } else {
    this.$createQuestionInput.hide()
    return this.setQbId()
  }
}

QuestionBankView.prototype.getSettings = function () {
  const settings = this.model.get('settings') || {}
  delete settings.question_bank_name
  delete settings.question_bank_id
  return settings
}

QuestionBankView.prototype.setQbName = function () {
  const settings = this.getSettings()
  const name = this.$createQuestionInput.val()
  if (name !== '') {
    settings.question_bank_name = name
  }
  return this.model.set('settings', settings)
}

QuestionBankView.prototype.setQbId = function () {
  const settings = this.getSettings()
  const id = this.$questionBankSelect.val()
  if (id !== '') {
    settings.question_bank_id = id
  }
  return this.model.set('settings', settings)
}

QuestionBankView.prototype.setEnabled = function (enabled, disabled_msg) {
  if (enabled) {
    this.$questionBankDisabledMsg.hide()
  } else {
    this.$questionBankSelect.val('')
    this.$createQuestionInput.hide()
    this.setQbId()
    if (disabled_msg) {
      this.$questionBankDisabledMsg.text(disabled_msg)
    }
    this.$questionBankDisabledMsg.show()
  }
  return this.$questionBankSelect.prop('disabled', !enabled)
}

QuestionBankView.prototype.toJSON = function () {
  return this.options
}

export default QuestionBankView
