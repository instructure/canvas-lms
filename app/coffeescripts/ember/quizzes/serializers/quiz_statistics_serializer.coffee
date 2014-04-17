define [ 'ember', 'ember-data' ], (Em, DS) ->
  respondentCount = 0

  calculateResponseRatio = (answer) ->
    Em.Util.round(answer.responses / respondentCount * 100)

  decorateAnswers = (answers) ->
    (answers || []).forEach (answer) ->
      # the ratio of responses for each answer out of the question's total responses
      answer.ratio = calculateResponseRatio(answer)

      # define a "correct" boolean so we can use it with bind-attr:
      if answer.correct == undefined and answer.weight != undefined
        answer.correct = answer.weight == 100
        # remove the weight to make sure the front-end isn't using this because
        # it will go away from the API output soon:
        delete answer.weight

  decorateAnswerSet = (answerSet) ->
    (answerSet.answer_matches || []).forEach (answer, i) ->
      answer.id = "#{answerSet.id}_#{i}"
      answer.ratio = calculateResponseRatio(answer)

  DS.ActiveModelSerializer.extend
    extractArray: (store, type, payload, id, requestType) ->
      data = {
        quizStatistics: payload.quiz_statistics
        questionStatistics: payload.quiz_statistics[0].question_statistics
      }

      data.questionStatistics.forEach (questionStatistics) ->
        questionStatistics.id = "#{questionStatistics.id}"

        # assign a FK between question and quiz statistics
        questionStatistics.quiz_statistics_id = data.quizStatistics[0].id

      @decorate(payload.quiz_statistics[0])

      # set of FKs between quiz and question stats
      data.quizStatistics[0].question_statistic_ids = Em.A(data.questionStatistics).mapBy('id')

      @_super(store, type, data, id, requestType)

    # TODO: remove once deprecated (the new stats API will expose these items)
    decorate: (quiz_statistics) ->
      participantCount = quiz_statistics.submission_statistics.unique_count

      quiz_statistics.question_statistics.forEach (questionStatistics) ->
        respondentCount = questionStatistics.responses || participantCount
        decorateAnswers(questionStatistics.answers)

        if questionStatistics.answer_sets
          questionStatistics.answer_sets.forEach(decorateAnswerSet)