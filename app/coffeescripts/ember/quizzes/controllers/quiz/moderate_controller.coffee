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

    needs: ['quiz']

    quiz: Ember.computed.alias('controllers.quiz.model')

    # student extension modal

    selectedStudents: []

    studentExtensionTitle:
      I18n.t 'student_extensions', 'Student Extensions'

    singleSelection: ( ->
      @get("selectedStudents.length") == 1
    ).property('selectedStudents')

    extensionsFor: ( ->
      if @get("singleSelection")
        student = @get("selectedStudents.firstObject.name")
        I18n.t('extensions_student', 'Extensions for %{student}', student: student)
      else
        I18n.t('extensions_num_students', 'Extensions for %{num} Students', num: @get('length'))
    ).property('selectedStudents')

    modalHeight: ( ->
      height = 220
      height += 60 if @get('quiz.timeLimit')
      height += 60 if !@get('unlimitedAttempts')
      height
    ).property('quiz.timeLimit', 'unlimitedAttempts')

    unlimitedAttempts: ( ->
      @get('quiz.multipleAttemptsAllowed') && @get('quiz.allowedAttempts') == -1
    ).property('quiz.multipleAttemptsAllowed', 'quiz.allowedAttempts')

    quizExtraAttemptsNote: ( ->
      I18n.t('everyone_gets_attempts', 'everyone already gets %{num}', num: @get('quiz.allowedAttempts'))
    ).property('quiz.allowedAttempts')

    quizExtraTimeNote: ( ->
      I18n.t('everyone_gets_time', 'everyone already gets %{num} minutes', num: @get('quiz.timeLimit'))
    ).property('quiz.timeLimit')

    extraAttempts: ( ->
      if @get("singleSelection")
        student = @get("selectedStudents").get("firstObject")
        student.get("quizSubmission").get("extraAttempts")
    ).property('selectedStudents')

    extraTime: ( ->
      if @get("singleSelection")
        student = @get("selectedStudents").get("firstObject")
        student.get("quizSubmission").get("extraTime")
    ).property('selectedStudents')

    manuallyUnlocked: ( ->
      if @get("singleSelection")
        student = @get("selectedStudents").get("firstObject")
        student.get("quizSubmission").get("manuallyUnlocked")
    ).property('selectedStudents')

    # /student extension modal

    actions:
      refreshData: ->
        @set('reloading', true)
        true

      # student extension modal
      submitStudentExtensions: ->
        quizExtensions = @get("selectedStudents").map (student) =>
          user_id: student.get("id")
          extra_attempts: @get('extraAttempts')
          extra_time: @get('extraTime')
          manually_unlocked: @get('manuallyUnlocked')

        options =
          url: @get("quiz").get('quizExtensionsUrl')
          data: JSON.stringify(quiz_extensions: quizExtensions)
          type: 'POST'
          dataType: 'json'
          contentType: 'application/json'
          headers: 'Accepts': 'application/vnd.api+json'

        ajax.raw(options).then =>
          $.flashMessage I18n.t 'extensions_successfully_added', 'Extensions Successfully Added'
          @send 'refreshData'

  QuizModerateController
