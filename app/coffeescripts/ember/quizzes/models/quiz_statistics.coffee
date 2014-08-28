define [
  'ember'
  'ember-data'
], (Em, DS) ->

  {alias} = Em.computed
  {attr} = DS

  DS.Model.extend
    quiz: DS.belongsTo 'quiz', async: false
    questionStatistics: DS.hasMany 'question_statistics', async: false

    generatedAt: attr('date')
    multipleAttemptsExist: attr('boolean')

    submissionStatistics: attr()

    avgCorrect: alias 'submissionStatistics.correct_count_average'
    avgIncorrect: alias 'submissionStatistics.incorrect_count_average'
    avgDuration: alias 'submissionStatistics.duration_average'
    loggedOutUsers: alias 'submissionStatistics.logged_out_users'
    avgScore: alias 'submissionStatistics.score_average'
    highScore: alias 'submissionStatistics.score_high'
    lowScore: alias 'submissionStatistics.score_low'
    scoreStdev: alias 'submissionStatistics.score_stdev'
    uniqueCount: alias 'submissionStatistics.unique_count'
