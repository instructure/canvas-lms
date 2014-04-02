define [
  'ember'
  'ember-data'
  'underscore'
  'i18n!quizzes'
], (Em, DS, _, I18n) ->

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

    renderableType: (->
      type = @get('questionType')

      if [ 'multiple_choice_question', 'true_false_question' ].indexOf(type) > -1
        'multiple_choice'
      else
        'generic'
    ).property('question_type')

    discriminationIndex: (->
      pointBiserials = @get('pointBiserials')

      unless pointBiserials
        return null

      _.findWhere(pointBiserials, { correct: true }).point_biserial
    ).property('pointBiserials')