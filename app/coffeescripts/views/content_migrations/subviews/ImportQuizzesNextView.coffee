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
  'Backbone'
  'i18n!content_migrations'
  'jst/content_migrations/subviews/ImportQuizzesNextView'
  'jquery'
], (Backbone, I18n, template, $) ->
  class ImportQuizzesNextView extends Backbone.View
    template: template
    @optionProperty 'quizzesNextEnabled'
    @optionProperty 'questionBank'

    events:
      "change #importQuizzesNext" : "setAttribute"

    setAttribute: =>
      settings = @model.get('settings') || {}
      checked = @$el.find('#importQuizzesNext').is(':checked')
      settings.import_quizzes_next = checked
      @questionBank.setEnabled(!checked,
        I18n.t('This option is not compatible with Quizzes.Next'))
      @model.set('settings', settings)

    toJSON: -> @options
