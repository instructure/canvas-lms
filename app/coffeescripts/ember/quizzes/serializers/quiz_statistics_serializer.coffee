define [ 'ember-data', 'underscore' ], (DS, _) ->
  DS.ActiveModelSerializer.extend
    extractArray: (store, type, payload, id, requestType) ->
      payload.question_statistics = payload.quiz_statistics[0].question_statistics

      # decorate the "answers" statistics for easier usage in views
      payload.question_statistics.forEach (questionStatistics) =>
        questionStatistics.answers.forEach (answer) =>
          # save the ratio/percentage of responses for each answer:
          answer.ratio = @calculateAnswerRatio(answer, questionStatistics)

          # define a "correct" boolean so we can use it with bind-attr:
          unless answer.weight == undefined
            answer.correct = answer.weight == 100

      @_super(store, type, payload, id, requestType)

    calculateAnswerRatio: (answer, questionStatistics) ->
      Math.round(answer.responses / questionStatistics.responses * 100)