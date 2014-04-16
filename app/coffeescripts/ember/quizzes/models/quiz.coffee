define [
  'ember'
  'ember-data'
  'i18n!quizzes'
], (Em, DS, I18n) ->

  {alias, equal, any} = Em.computed
  {belongsTo} = DS

  Em.onerror = (error) ->
    console.log 'ERR', error, error.stack

  {Model, attr} = DS
  Model.extend
    title: attr()
    quizType: attr()
    htmlURL: attr()
    # editURL is temporary until we have a real ember route for it
    editURL: (->
      "#{@get('htmlURL')}/edit"
    ).property('htmlURL')
    allDates: attr()
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
