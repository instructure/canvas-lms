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
  'jst/content_migrations/subviews/QuestionBank'
  'jquery'
], (Backbone, template, $) ->
  class QuestionBankView extends Backbone.View
    template: template
    @optionProperty 'questionBanks'
    @optionProperty 'disabled_message'

    els:
      ".questionBank" : "$questionBankSelect"
      "#createQuestionInput" : "$createQuestionInput"
      "#questionBankDisabledMsg" : "$questionBankDisabledMsg"

    events:
      'change .questionBank'              :  'setQuestionBankValues'
      'keyup #createQuestionInput'        :  'updateNewQuestionName'

    initialize:(options) ->
        options.is_disabled = false
        super

    updateNewQuestionName: (event) =>
      @setQbName()

    setQuestionBankValues: (event) ->
      if (event.target.value == 'new_question_bank')
        @$createQuestionInput.show()
        # Ensure focus is on the new input field
        @$createQuestionInput.focus()
        @setQbName()
      else
        @$createQuestionInput.hide()
        @setQbId()

    getSettings: ->
      settings = @model.get('settings') || {}
      delete settings.question_bank_name
      delete settings.question_bank_id
      return settings

    setQbName: ->
      settings = @getSettings()
      name = @$createQuestionInput.val()
      settings.question_bank_name = name if name != ""
      @model.set 'settings', settings

    setQbId: ->
      settings = @getSettings()
      id = @$questionBankSelect.val()
      settings.question_bank_id = id if id != ""
      @model.set 'settings', settings

    setEnabled: (enabled, disabled_msg) ->
      if enabled
        @$questionBankDisabledMsg.hide()
      else
        @$questionBankSelect.val( '' )
        @$createQuestionInput.hide()
        @setQbId()
        if disabled_msg
            @$questionBankDisabledMsg.text(disabled_msg)
        @$questionBankDisabledMsg.show()
      @$questionBankSelect.prop('disabled', !enabled)

    toJSON: -> @options

