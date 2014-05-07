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
    hasSubmission: Ember.computed.bool('quizSubmission.id')
    quiz: Ember.computed.alias('controllers.quiz.model')
    okayToReload: Ember.computed.bool('controllers.quiz_moderate.okayToReload')

    selected: false
    missingIndicator: '--'

    attempts: ( ->
      return @get('missingIndicator') if !@get('hasSubmission')
      @get('quizSubmission.attempt')
    ).property('quizSubmission.attempt')

    friendlyScore: ( ->
      return if @get('isActive') || !@get('keptScore')
      "#{@get('keptScore')} / #{@get('quizPointsPossible')}"
    ).property('keptScore', 'quizPointsPossible', 'isActive')

    remainingAttempts: ( ->
      return if @get('unlimitedAttempts')
      if !@get('hasSubmission')
        remaining = @get('quiz.allowedAttempts')
      else
        remaining = parseInt(@get('allowedAttempts'), 10) - parseInt(@get('attempts'), 10)
      Math.max(remaining, 0)
    ).property('attempts', 'allowedAttempts', 'mulitpleAttemptsAllowed', 'unlimitedAttempts')

    remainingStatusLabel: ( ->
      if @get('unlimitedAttempts')
        I18n.t 'unlimited', 'Unlimited'
      else
        ''
    ).property('unlimitedAttempts')

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
