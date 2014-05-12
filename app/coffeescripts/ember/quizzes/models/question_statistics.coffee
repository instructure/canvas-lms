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
      switch @get('questionType')
        when 'multiple_choice_question', 'true_false_question'
          'multiple_choice'
        when 'short_answer_question', 'multiple_answers_question'
          'short_answer'
        else
          'generic'
    ).property('questionType')

    discriminationIndex: (->
      pointBiserials = @get('pointBiserials') || []
      pointBiserials.findBy('correct', true).point_biserial
    ).property('pointBiserials')

    hasMultipleAnswers: ->
      Em.A([ 'multiple_answers_question' ]).contains(@get('questionType'))

    # Calculates the ratio of students who answered this question correctly
    # (partially correct answers do not count when applicable)
    #
    # TODO: this is better done on the back-end, but until then we'll do it here
    correctResponseRatio: (->
      participants = @get('quizStatistics.uniqueCount')

      return 0 if participants <= 0
      return @__correctMultipleResponseRatio() if @hasMultipleAnswers()

      correctResponses = @get('answers').reduce (sum, answer) ->
        sum += answer.responses if answer.correct
        sum
      , 0

      correctResponses / participants
    ).property('questionType', 'answers', 'quizStatistics.uniqueCount')

    # Calculates a similar ratio to #correctResponseRatio but for questions that
    # have multiple correct answers where the answer may be partially correct,
    # in which case it is not counted.
    #
    # @private
    #
    # Please don't use this directly, use #correctResponseRatio instead.
    __correctMultipleResponseRatio: ->
      respondentsFor = (answerSet, flatten) ->
        respondents = answerSet.map (answer) -> answer.user_ids
        if flatten then _.flatten(respondents) else respondents

      participants = @get 'quizStatistics.uniqueCount'
      correctAnswers = @get('answers').filterBy 'correct', true
      distractors = @get('answers').filterBy 'correct', false

      # we need students who have picked all correct answers:
      correctRespondents = _.intersection.apply _, respondentsFor(correctAnswers)

      # and none of the wrong ones:
      correctRespondents =
        _.difference(correctRespondents, respondentsFor(distractors, true))

      correctRespondents.length / participants