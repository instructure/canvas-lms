define [ 'ember' ], (Em) ->
  MULTIPLE_ANSWERS = 'multiple_answers_question'

  # A utility class for calculating response ratios for a given question
  # statistics object.
  #
  # The ratio calculation may differ based on the question type, this class
  # takes care of it by exposing a single API #ratio() that hides those details
  # from you.
  #
  # Usage: see QuestionStatistics#ratioCalculator.
  Calculator = Em.ObjectProxy.extend
    participantCount: Em.computed.alias('quizStatistics.uniqueCount')

    # @property [Array<Object>] answerPool
    # This is the set of answers that we'll use to calculate the ratio.
    #
    # Synopsis of the expected answer objects in the set:
    #
    #   {
    #     "responses": 0,
    #     "correct": true
    #   }
    #
    # Most question types will have these defined in the top-level "answers" set,
    # but for some others that support answer sets, these could be found in
    # answer_sets.@each.answer_matches.
    #
    # @note
    # Can't use Em.computed.alias() here because this property is mutable
    # and we don't want to side-effect against the question's #answers.
    answerPool: (-> @get('answers') ).property('answers')

    # Calculates the ratio of students who answered this question correctly
    # (partially correct answers do not count when applicable)
    #
    # @return [Number] A scalar, the ratio.
    ratio: (->
      participantCount = @get('participantCount') || 0

      return 0 if participantCount <= 0

      if isMultipleAnswers(@get('questionType'))
        return ratioForMultipleAnswers.call(this)

      correctResponses = @get('answerPool').reduce (sum, answer) ->
        sum += answer.responses if answer.correct
        sum
      , 0

      correctResponses / participantCount
    ).property('answerPool', 'participantCount')

  # @private
  isMultipleAnswers = (questionType) ->
    MULTIPLE_ANSWERS == questionType

  # @private
  #
  # Calculates a similar ratio to #ratio but for questions that require a
  # student to choose more than one answer for their response to be considered
  # correct. As such, a "partially" correct response does not count towards
  # the correct response ratio.
  ratioForMultipleAnswers = () ->
    @get('correct') / @get('participantCount')

  Calculator