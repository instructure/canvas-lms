define [
  'ember'
  'ember-data'
  'i18n!quiz_model'
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
    #at some point we may need this as a relationship
    assignmentId: attr()
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
    sectionCount: attr()
    accessCode: attr()
    ipFilter: attr()
    pointsPossible: attr()
    published: attr()
    deleted: attr()
    speedGraderUrl: attr()
    moderateUrl: attr()
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
        when 'keep_highest' then I18n.t('keep_highest', 'Highest')
        when 'keep_latest' then I18n.t('keep_latest', 'Latest')
    ).property('scoringPolicy')
    tQuizType: (->
      switch @get('quizType')
        when 'assignment' then I18n.t 'assignment', 'Assignment'
        when 'survey' then I18n.t 'survey', 'Survey'
        when 'graded_survey' then I18n.t 'graded_survey', 'Graded Survey'
        when 'practice_quiz' then I18n.t 'practice_quiz', 'Practice Quiz'
    ).property('quizType')

    quizSubmissionHtmlUrl: attr()
    quizSubmissionVersionsHtmlUrl: attr()

    quizStatistics: hasMany 'quiz_statistics', async: true
    quizReports: hasMany 'quiz_report', async: true
    users: hasMany 'user', async: true
    studentQuizSubmissions: hasMany 'student_quiz_submission', async: true
    sortSlug: (->
      dateField = if @get('isAssignment') then 'dueAt' else 'lockAt'
      dueAt = @get(dateField)?.toISOString() or Quiz.SORT_LAST
      title = @get('title') or ''
      dueAt + title
    ).property('isAssignment', 'dueAt', 'lockAt', 'title')
    assignmentOverrides: hasMany 'assignment_override'
    allDates: (->
      dates = []
      overrides = @get('assignmentOverrides').toArray()
      if overrides.length == 0 || overrides.length != @get 'sectionCount'
        title = if overrides.length > 0
          I18n.t('everyone_else', 'Everyone Else')
        else
          I18n.t('everyone', 'Everyone')
        dates.push Ember.Object.create
          lockAt: @get 'lockAt'
          unlockAt: @get 'unlockAt'
          dueAt: @get 'dueAt'
          base: true
          title: title

      Ember.A(dates.concat(overrides))
    ).property('lockAt', 'unlockAt', 'dueAt', 'sectionCount', 'assignmentOverrides.[]')
    submittedStudents: hasMany 'submitted_student', polymporphic: true, async: true
    unsubmittedStudents: hasMany 'unsubmitted_student', polymorphic: true, async: true
    messageStudentsUrl: attr()
    quizExtensionsUrl: attr()
    quizSubmission: belongsTo 'quiz_submission'
    quizSubmissions: alias('studentQuizSubmissions')
    takeable: attr()
    takeQuizUrl: attr()
    quizSubmissionsZipUrl: attr()
    previewUrl: attr()

  Quiz.SORT_LAST = 'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ'

  Quiz
