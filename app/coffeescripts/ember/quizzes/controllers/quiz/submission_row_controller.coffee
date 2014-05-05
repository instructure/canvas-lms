define [
  'ember'
  '../../shared/seconds_to_time'
  '../../shared/environment'
], (Em, formatSeconds, env) ->

  Em.ObjectController.extend

    needs: ['quiz']

    timeSpent: Ember.computed.alias('quizSubmission.timeSpent')
    allowedAttempts: Ember.computed.alias('quizSubmission.quiz.allowedAttempts')
    multipleAttemptsAllowed: Ember.computed.alias('quizSubmission.quiz.multipleAttemptsAllowed')
    keptScore: Ember.computed.alias('quizSubmission.keptScore')
    quizPointsPossible: Ember.computed.alias('quizSubmission.quizPointsPossible')
    hasSubmission: Ember.computed.bool('quizSubmission.id')

    selected: false
    missingIndicator: '--'

    attempts: ( ->
      return @get('missingIndicator') if !@get('hasSubmission')
      @get('quizSubmission.attempt')
    ).property('quizSubmission.attempt')

    friendlyTime: ( ->
      return if !@get('hasSubmission')
      formatSeconds(@get('timeSpent'))
    ).property('timeSpent')

    friendlyScore: ( ->
      return if !@get('hasSubmission')
      "#{@get('keptScore')} / #{@get('quizPointsPossible')}"
    ).property('score', 'quizPointsPossible')

    remainingAttempts: ( ->
      if !@get('hasSubmission')
        remaining = @get('controllers.quiz.model.allowedAttempts')
      else
        remaining = parseInt(@get('allowedAttempts'), 10) - parseInt(@get('attempts'), 10)
      return Math.max(remaining, 0)
    ).property('attempts', 'allowedAttempts', 'mulitpleAttemptsAllowed')

    historyLink: ( ->
      partial = "history?quiz_submission_id=#{@get('quizSubmission.id')}"
      quizId = @get('controllers.quiz.model.id')
      courseId = env.get('courseId')
      "/courses/#{courseId}/quizzes/#{quizId}/#{partial}"
    ).property('quizSubmission.id')
