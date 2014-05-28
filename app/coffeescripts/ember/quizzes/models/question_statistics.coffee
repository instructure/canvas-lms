define [
  'ember'
  'ember-data'
  'i18n!quizzes'
], (Em, DS, I18n) ->

  {alias} = Em.computed
  {Model, attr, belongsTo} = DS

  Model.extend
    quizStatistics: belongsTo 'quizStatistics', async: false
    questionType: attr()
    questionName: attr()
    questionText: attr()
    position: attr()
    answers: attr()
    pointBiserials: attr()
    responses: attr()
    responseValues: attr()
    unexpectedResponseValues: attr()
    topStudentCount: attr()
    middleStudentCount: attr()
    bottomStudentCount: attr()
    correctStudentCount: attr()
    incorrectStudentCount: attr()
    correctStudentRatio: attr()
    incorrectStudentRatio: attr()
    correctTopStudentCount: attr()
    correctMiddleStudentCount: attr()
    correctBottomStudentCount: attr()