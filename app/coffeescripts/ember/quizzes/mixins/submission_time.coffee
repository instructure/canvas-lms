define [
  'ember'
  '../shared/seconds_to_time'
  'i18nObj'
], (Ember, secondsToTime, I18n) ->

  MS_PER_SECOND = 1000
  MS_PER_MINUTE = 60 * MS_PER_SECOND
  SECONDS_PER_MINUTE = 60
  REFRESH_DELAY = 1000

  ###
  # SubmissionTime Mixin calculates various times for QuizSubmissions
  # Counts up or down for open submissions, based on quiz type
  #
  # expects host to object to have:
  #
  #   quizSubmission: QuizSubmission
  #   okayToReload: bool
  #
  ###
  Ember.Mixin.create

    runningTime: undefined
    timeSpent: Ember.computed.alias('quizSubmission.timeSpent')
    timeLimit: Ember.computed.alias('quizSubmission.quiz.timeLimit')
    endAt: Ember.computed.alias('quizSubmission.endAt')
    dueAt: Ember.computed.alias('quizSubmission.quiz.dueAt')
    lockAt: Ember.computed.alias('quizSubmission.quiz.lockAt')

    isActive: ( ->
      @get('quizSubmission.startedAt') && !@get('quizSubmission.finishedAt')
    ).property('quizSubmission.startedAt', 'quizSubmission.finishedAt')

    friendlyEndsAt: ( ->
      date = @get('endAt')
      return unless date
      I18n.l('date.formats.date_at_time', date)
    ).property('endAt')

    startStopRunningTime: (  ->
      if @get('isActive') && @get('okayToReload')
        if !@get('runningTime')
          Ember.run.next this, @updateRunningTime
        else
          Ember.run.debounce this, @updateRunningTime, REFRESH_DELAY
      else
        @set('runningTime', undefined)
    ).observes('isActive', 'okayToReload').on('init')

    friendlyTime: ( ->
      return if !@get('timeSpent')
      timeLimit = @get('timeLimit')
      timeSpent = @get('timeSpent')
      #actual timeSpent can be a few seconds over limit when auto submit modal
      #is in play, don't show timeSpent to be any bigger than timeLimit
      if timeLimit
        timeSpent = Math.min(timeSpent, (timeLimit * SECONDS_PER_MINUTE))
      secondsToTime(timeSpent)
    ).property('timeSpent')

    updateRunningTime: ->
      if @get('timeLimit')
        seconds = @calcRemainingSeconds()
      else
        seconds = @calcCurrentSeconds()
      if @isTimeExpired()
        @closeOutSubmission()
      @set('runningTime', secondsToTime(seconds))
      @startStopRunningTime()

    # locally close out submission, this doesn't persist anything, only stops
    # any possible UI displays of time running
    closeOutSubmission: ->
      @set('quizSubmission.finishedAt', new Date().toISOString())
      @set('quizSubmission.timeSpent', @calcCurrentSeconds())

    calcRemainingSeconds: () ->
      seconds = (new Date(@get('endAt')).getTime() - new Date().getTime()) / MS_PER_SECOND
      Math.round seconds

    calcCurrentSeconds: ->
      started = new Date(@get('quizSubmission.startedAt'))
      Math.floor((new Date() - started) / MS_PER_SECOND)

    isTimeExpired: ->
      return false if !@get('endAt')
      @calcRemainingSeconds() <= 0
