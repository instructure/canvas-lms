define [
  'Backbone'
  'jst/content_migrations/subviews/QuestionBank'
  'jquery'
], (Backbone, template, $) -> 
  class QuestionBankView extends Backbone.View
    template: template
    @optionProperty 'questionBanks'

    els:
      ".questionBank" : "$questionBankSelect"
      "#createQuestionInput" : "$createQuestionInput"

    events: 
      'change .questionBank'              :  'setQuestionBankValues'
      'keyup #createQuestionInput'        :  'updateNewQuestionName'

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

    toJSON: -> @options

