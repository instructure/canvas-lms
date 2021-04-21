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

import Backbone from 'Backbone'
import I18n from 'i18n!content_migrations'
import template from 'jst/content_migrations/subviews/ImportQuizzesNextView'
import $ from 'jquery'

export default class ImportQuizzesNextView extends Backbone.View
  template: template
  @optionProperty 'quizzesNextEnabled'
  @optionProperty 'migrationDefault'
  @optionProperty 'questionBank'

  events:
    "change #importQuizzesNext" : "setAttribute"

  afterRender: ->
    @setAttribute()

  setAttribute: =>
    settings = @model.get('settings') || {}
    checked = @$el.find('#importQuizzesNext').is(':checked')
    settings.import_quizzes_next = checked
    @updateQuestionBank(checked)
    @model.set('settings', settings)

  updateQuestionBank: (checked) ->
    if @questionBank?
      @questionBank.setEnabled(!checked,
        I18n.t('This option is not compatible with New Quizzes'))

  toJSON: -> @options
