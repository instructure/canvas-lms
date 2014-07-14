define [
  'ember'
  'ember-data'
  './question_statistics/response_ratio_calculator'
], (Em, DS, ResponseRatioCalculator) ->

  {alias} = Em.computed
  {attr} = DS

  DS.Model.extend
    quizStatistics: DS.belongsTo 'quiz_statistics', async: false

    questionType: attr()
    questionName: attr()
    questionText: attr()
    position: attr()

    # Shared
    answers: attr()
    responses: attr()
    correct: attr('number')
    partiallyCorrect: attr('number')

    # Multiple-Choice & True/False
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
    pointBiserials: attr()
    discriminationIndex: (->
      if pointBiserials = @get('pointBiserials')
        pointBiserials.findBy('correct', true).point_biserial
    ).property('pointBiserials')

    # Essay
    graded: attr()
    pointDistribution: attr()
    speedGraderUrl: alias('quizStatistics.quiz.speedGraderUrl').readOnly()

    # Essay & Numerical
    fullCredit: attr()

    # File Upload
    quizSubmissionsZipUrl: alias('quizStatistics.quiz.quizSubmissionsZipUrl').readOnly()

    # Multiple-Dropdowns, FIMB, Matching
    answerSets: (->
      sets = @get('_data.answer_sets') || []
      sets.map (set) ->
        Em.Object.create(set)
    ).property('_data.answer_sets')

    # Helper for calculating the ratio of correct responses for this question.
    #
    # Usage: @get('questionStatistics.ratioCalculator.ratio')
    ratioCalculator: (->
      ResponseRatioCalculator.create({ content: this })
    ).property('answers')

    # @internal
    renderableType: (->
      switch @get('questionType')
        when 'multiple_choice_question', 'true_false_question'
          'multiple_choice'
        when 'short_answer_question', 'multiple_answers_question', 'numerical_question'
          'short_answer'
        when 'fill_in_multiple_blanks_question', 'multiple_dropdowns_question', 'matching_question'
          'fill_in_multiple_blanks'
        when 'essay_question'
          'essay'
        when 'file_upload_question'
          'file_upload'
        when 'calculated_question'
          'calculated'
        else
          'generic'
    ).property('questionType')
