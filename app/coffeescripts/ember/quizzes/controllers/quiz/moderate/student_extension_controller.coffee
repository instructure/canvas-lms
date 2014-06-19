define [
  'ember'
  'ic-ajax'
  'i18n!quiz_extensions'
], (Em, ajax, I18n) ->

  StudentExtensionsController = Em.ArrayController.extend
    needs: ['quiz']
    quiz: Ember.computed.alias('controllers.quiz.model')
    extension: Ember.Object.create

    title: I18n.t 'student_extensions', 'Student Extensions'

    extensionsFor: ( ->
      if @get("length") == 1
        student = @get("firstObject.name")
        I18n.t('extensions_student', 'Extensions for %{student}', student: student)
      else
        I18n.t('extensions_num_students', 'Extensions for %{num} Students', num: @get('length'))
    ).property('@each')

    modalHeight: ( ->
      height = 220
      height += 60 if @get('quiz.timeLimit')
      height += 60 if !@get('unlimitedAttempts')
      height
    ).property('quiz.timeLimit', 'unlimitedAttempts')

    unlimitedAttempts: ( ->
      @get('quiz.multipleAttemptsAllowed') && @get('quiz.allowedAttempts') == -1
    ).property('quiz.multipleAttemptsAllowed', 'quiz.allowedAttempts')

    extraAttemptsNote: ( ->
      I18n.t('everyone_gets_attempts', 'everyone already gets %{num}', num: @get('quiz.allowedAttempts'))
    ).property('quiz.allowedAttempts')

    extraTimeNote: ( ->
      I18n.t('everyone_gets_time', 'everyone already gets %{num} minutes', num: @get('quiz.timeLimit'))
    ).property('quiz.timeLimit')

    # setup the extension object with defaults based on the selected students
    setupExtension: ( ->
      if @get('length') == 1
        qs = @get("firstObject.quizSubmission")
        @set("extension.extraAttempts", qs.get("extraAttempts"))
        @set("extension.extraTime", qs.get("extraTime"))
        @set("extension.manuallyUnlocked", qs.get("manuallyUnlocked"))
      else
        allUnlocked = @everyProperty('quizSubmission.manuallyUnlocked', true)
        @set("extension.manuallyUnlocked", !!@get('length') && allUnlocked)
    ).observes('model')

    actions:
      submit: ->
        quizExtensions = @get("model").map (student) =>
          user_id: student.get("id")
          extra_attempts: @get('extension.extraAttempts')
          extra_time: @get('extension.extraTime')
          manually_unlocked: @get('extension.manuallyUnlocked')

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


