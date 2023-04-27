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
import {useScope as useI18nScope} from '@canvas/i18n'
import template from '../../jst/ImportQuizzesNextView.handlebars'

const I18n = useI18nScope('content_migrations')

extend(ImportQuizzesNextView, Backbone.View)

function ImportQuizzesNextView() {
  this.setAttribute = this.setAttribute.bind(this)
  return ImportQuizzesNextView.__super__.constructor.apply(this, arguments)
}

ImportQuizzesNextView.prototype.template = template

ImportQuizzesNextView.optionProperty('quizzesNextEnabled')

ImportQuizzesNextView.optionProperty('migrationDefault')

ImportQuizzesNextView.optionProperty('questionBank')

ImportQuizzesNextView.prototype.events = {
  'change #importQuizzesNext': 'setAttribute',
}

ImportQuizzesNextView.prototype.afterRender = function () {
  return this.setAttribute()
}

ImportQuizzesNextView.prototype.setAttribute = function () {
  const settings = this.model.get('settings') || {}
  const checked = this.$el.find('#importQuizzesNext').is(':checked')
  settings.import_quizzes_next = checked
  this.updateQuestionBank(checked)
  return this.model.set('settings', settings)
}

ImportQuizzesNextView.prototype.updateQuestionBank = function (checked) {
  if (this.questionBank != null) {
    return this.questionBank.setEnabled(
      !checked,
      I18n.t('This option is not compatible with New Quizzes')
    )
  }
}

ImportQuizzesNextView.prototype.toJSON = function () {
  return this.options
}

export default ImportQuizzesNextView
