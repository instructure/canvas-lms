define [
  'Backbone'
  'jst/content_migrations/subviews/QuestionBank'
  'jquery'
], (Backbone, template, $) -> 
  class QuestionBankView extends Backbone.View
    template: template
    @optionProperty 'questionBanks'

    els: 
      "#createQuestionInput" : "$createQuestionInput"

    events: 
      'change .questionBank'              :  'setQuestionBankValues'
      'keyup #createQuestionInput'        :  'updateNewQuestionName'

    updateNewQuestionName: (event) => 
      @model.set 'settings', {question_bank_name: event.target.value}

    setQuestionBankValues: (event) -> 
      if(event.target.value == 'new_question_bank') 
        @$createQuestionInput.show()

        # Ensure focus is on the new input field
        @$createQuestionInput.focus()
        @model.set 'settings', {question_bank_id: null}
      else
        @$createQuestionInput.hide()
        @model.set 'settings', {question_bank_id: event.target.value}
        @model.set 'settings', {question_bank_name: null}

    toJSON: -> @options

