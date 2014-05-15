define [
  'ember'
  'ember-data'
], (Em, DS, ajax) ->

  {alias, equal, any} = Em.computed
  computed = Em.computed
  {belongsTo, hasMany, Model, attr} = DS

  QuizSubmission = Model.extend
    user: belongsTo 'user', async: false
    quiz: belongsTo 'quiz', async: false
    attempt: attr('number')
    endAt: attr()
    extraAttempts: attr('number')
    extraTime: attr()
    finishedAt: attr()
    fudgePoints: attr()
    htmlUrl: attr()
    keptScore: attr()
    quizPointsPossible: attr()
    quizVersion: attr()
    score: attr()
    scoreBeforeRegrade: attr()
    startedAt: attr()
    timeSpent: attr()
    validationToken: attr()
    workflowState: attr()
    isCompleted: computed.or 'isPendingReview', 'isComplete'
    isComplete: equal 'workflowState', 'complete'
    isPendingReview: equal 'workflowState', 'pending_review'
    isUntaken: equal 'workflowState', 'untaken'
    attemptsLeft: attr()
