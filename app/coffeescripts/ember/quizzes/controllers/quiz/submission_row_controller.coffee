define [
  'ember'
  '../../shared/seconds_to_time'
  '../../shared/environment'
  'i18n!quizzez_submission_row'
  '../../mixins/submission_time'
], (Em, formatSeconds, env, I18n, SubmissionTime) ->

  Em.ObjectController.extend SubmissionTime,

    needs: ['quiz', 'quiz_moderate']

    allowedAttempts: Ember.computed.alias('quizSubmission.quiz.allowedAttempts')
    multipleAttemptsAllowed: Ember.computed.alias('quizSubmission.quiz.multipleAttemptsAllowed')
    keptScore: Ember.computed.alias('quizSubmission.keptScore')
    quizPointsPossible: Ember.computed.alias('quizSubmission.quizPointsPossible')
    hasActiveSubmission: Ember.computed.bool('quizSubmission.startedAt')
    quiz: Ember.computed.alias('controllers.quiz.model')
    okayToReload: Ember.computed.bool('controllers.quiz_moderate.okayToReload')

    selected: false

    attempts: ( ->
      return if !@get('hasActiveSubmission')
      @get('quizSubmission.attempt')
    ).property('quizSubmission.attempt')

    friendlyScore: ( ->
      return if @get('isActive') || (!@get('keptScore') && @get('keptScore') != 0)
      "#{@get('keptScore')} / #{@get('quizPointsPossible')}"
    ).property('keptScore', 'quizPointsPossible', 'isActive')

    remainingAttempts: ( ->
      return if @get('unlimitedAttempts')
      if !@get('hasActiveSubmission')
        remaining = @get('quiz.allowedAttempts')
      else
        remaining = parseInt(@get('allowedAttempts'), 10) - parseInt(@get('attempts'), 10)
      extra = @get('quizSubmission.extraAttempts')
      remaining += parseInt(extra, 10) if extra
      Math.max(remaining, 0)
    ).property('attempts', 'allowedAttempts', 'mulitpleAttemptsAllowed',
               'unlimitedAttempts', 'quizSubmission.extraAttempts')

    remainingStatusLabel: ( ->
      if @get('unlimitedAttempts')
        I18n.t 'unlimited', 'Unlimited'
      else
        ''
    ).property('unlimitedAttempts')

    extraTimeAllowed: ( ->
      @get('quizSubmission.extraTime') && @get('quizSubmission.extraTime') > 0
    ).property('quizSubmission.extraTime')

    extraTimeOnAttempt: ( ->
      I18n.t('gets_extra_minutes', 'gets %{num} extra minutes on each attempt', num: @get('quizSubmission.extraTime'))
    ).property('quizSubmission.extraTime')

    unlimitedAttempts: ( ->
      @get('quiz.multipleAttemptsAllowed') && @get('quiz.allowedAttempts') == -1
    ).property('quiz.multipleAttemptsAllowed', 'quiz.allowedAttempts')

    historyLink: ( ->
      return null if !@get('quizSubmission.id')
      partial = "history?quiz_submission_id=#{@get('quizSubmission.id')}"
      quizId = @get('controllers.quiz.model.id')
      courseId = env.get('courseId')
      "/courses/#{courseId}/quizzes/#{quizId}/#{partial}"
    ).property('quizSubmission.id')
