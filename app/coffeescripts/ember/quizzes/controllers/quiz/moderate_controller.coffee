define [
  'ember'
  'ic-ajax'
  'i18n!quiz_moderate'
], (Em, ajax, I18n) ->

  INITIAL_REFRESH_MS = 60000
  LATER_REFRESH_MS = 180000

  QuizModerateController = Em.ArrayController.extend
    headerChecked: false
    reloading: false
    okayToReload: true

    setupAutoReload: (->
      Ember.run.later this, @triggerReload, INITIAL_REFRESH_MS
    ).on('init')

    triggerReload: ->
      @send('refreshData')
      Ember.run.later this, @triggerReload, LATER_REFRESH_MS

    checkedStudents: ( ->
      @filterProperty('isChecked', true)
    ).property('@each.isChecked')

    allChecked: ( (key, value) ->
      if value == undefined
        !!@get('length') && @everyProperty('isChecked', true)
      else
        @setEach('isChecked', value)
    ).property('@each.isChecked')

    changeExtensionFor: ( ->
      I18n.t('change_extension_for', "Change extension for %{num} Students", num: @get("checkedStudents.length"))
    ).property('checkedStudents')

    studentsHaveTakenQuiz: ( ->
      complete = @filterProperty('quizSubmission.isComplete', true).get("length")
      total = @get("length")
      I18n.t('students_have_taken', '%{complete} of %{total} students have completed this quiz', complete: complete, total: total)
    ).property('@each.quizSubmission.isComplete')

  QuizModerateController
