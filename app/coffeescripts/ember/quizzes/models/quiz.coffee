define [
  'ember'
  'ember-data'
  'i18n!quizzes'
  '../shared/ic-ajax-jsonapi'
], (Em, DS, I18n, ajax) ->

  {alias, equal, any} = Em.computed
  {belongsTo, PromiseObject, hasMany, Model, attr} = DS

  Em.onerror = (error) ->
    console.log 'ERR', error, error.stack
    throw new Ember.Error error

  {Model, attr} = DS
  Quiz = Model.extend
    title: attr()
    quizType: attr()
    links: attr()
    htmlURL: attr()
    # editURL is temporary until we have a real ember route for it
    editURL: (->
      "#{@get('htmlURL')}/edit"
    ).property('htmlURL')
    mobileURL: attr()
    description: attr()
    timeLimit: attr()
    shuffleAnswers: attr()
    hideResults: attr()
    showCorrectAnswers: attr()
    showCorrectAnswersAt: attr 'date'
    hideCorrectAnswersAt: attr 'date'
    scoringPolicy: attr()
    oneQuestionAtATime: attr()
    questionCount: attr()
    accessCode: attr()
    ipFilter: attr()
    pointsPossible: attr()
    published: attr()
    speedGraderUrl: attr()
    allowedAttempts: attr('number')
    unpublishable: attr()
    canNotUnpublish: equal 'unpublishable', false
    lockedForUser: attr()
    lockInfo: attr()
    lockExplanation: attr()
    dueAt: attr 'date'
    unlockAt: attr 'date'
    lockAt: attr 'date'
    permissions: attr()
    canUpdate: alias 'permissions.update'
    canManage: alias 'permissions.manage'
    isAssignment: equal 'quizType', 'assignment'
    isPracticeQuiz: equal 'quizType', 'practice_quiz'
    isSurvey: any 'isUngradedSurvey', 'isGradedSurvey'
    isGradedSurvey: equal 'quizType', 'graded_survey'
    isUngradedSurvey: equal 'quizType', 'survey'
    unlimitedAllowedAttempts: equal 'allowedAttempts', -1
    multipleAttemptsAllowed: (->
      @get('allowedAttempts') != 1
    ).property('allowedAttempts')
    alwaysShowResults: equal 'hideResults', null
    showResultsAfterLastAttempt: equal 'hideResults', 'until_after_last_attempt'
    assignmentGroup: belongsTo 'assignment_group', async: true
    tScoringPolicy: (->
      switch @get('scoringPolicy')
        when 'keep_highest' then I18n.t('highest', 'highest')
        when 'keep_latest' then I18n.t('latest', 'latest')
    ).property('scoringPolicy')
    tQuizType: (->
      switch @get('quizType')
        when 'assignment' then I18n.t 'assignment', 'Assignment'
        when 'survey' then I18n.t 'survey', 'Survey'
        when 'graded_survey' then I18n.t 'graded_survey', 'Graded Survey'
        when 'practice_quiz' then I18n.t 'practice_quiz', 'Practice Quiz'
    ).property('quizType')
    # temporary until we ship the show page with quiz submission info in ember
    quizSubmissionHtmlURL: attr()
    quizSubmissionHTML: (->
      promise = ajax(
        url: @get 'quizSubmissionHtmlURL'
        dataType: 'html'
        contentType: 'text/html'
        headers:
          Accept: 'text/html'
      ).then (html) =>
        @set 'didLoadQuizSubmissionHTML', true
        { html: html }
      PromiseObject.create promise: promise
    ).property('quizSubmissionHtmlURL')
    quizStatistics: hasMany 'quiz_statistics', async: true
    quizReports: hasMany 'quiz_report', async: true
    users: hasMany 'user', async: true
    quizSubmissions: hasMany 'quiz_submission', async: true
    sortSlug: (->
      dateField = if @get('isAssignment') then 'dueAt' else 'lockAt'
      dueAt = @get(dateField)?.toISOString() or Quiz.SORT_LAST
      title = @get('title') or ''
      dueAt + title
    ).property('isAssignment', 'dueAt', 'lockAt', 'title')
    assignmentOverrides: hasMany 'assignment_override'
    allDates: (->
      dates = []
      dates.push Ember.Object.create
        lockAt: @get 'lockAt'
        unlockAt: @get 'unlockAt'
        dueAt: @get 'dueAt'
        base: true
      dates = dates.concat(@get('assignmentOverrides').toArray())
      Ember.A(dates)
    ).property('lockAt', 'unlockAt', 'dueAt', 'assignmentOverrides.[]')

  Quiz.SORT_LAST = 'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ'

  Quiz
