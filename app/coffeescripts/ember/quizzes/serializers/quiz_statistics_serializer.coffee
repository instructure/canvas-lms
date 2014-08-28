define [
  'ember'
  'ember-data'
  'i18n!quiz_statistics'
  '../shared/util'
], (Ember, DS, I18n, Util) ->
  decorate = (quiz_statistics) ->
    {round} = Util
    participantCount = quiz_statistics.submission_statistics.unique_count

    calculateResponseRatio = (answer) ->
      if participantCount > 0 # guard against div by zero
        round(answer.responses / participantCount * 100)
      else
        0

    decorateAnswers = (answers) ->
      answers.forEach (answer) ->
        # the ratio of responses for each answer out of the question's total responses
        answer.ratio = calculateResponseRatio(answer)

        if answer.id == 'none'
          answer.text = I18n.t('no_answer', 'No Answer')
        else if answer.id == 'other'
          answer.text = I18n.t('unknown_answer', 'Something Else')

    decorateAnswerSet = (answerSet) ->
      decorateAnswers answerSet.answers || []

    quiz_statistics.question_statistics.forEach (question_statistics) ->
      # assign a FK between question and quiz statistics
      question_statistics.quiz_statistics_id = quiz_statistics.id

      if question_statistics.answers
        decorateAnswers(question_statistics.answers)

      if question_statistics.answer_sets
        question_statistics.answer_sets.forEach(decorateAnswerSet)

    # set of FKs between quiz and question stats
    quiz_statistics.question_statistics_ids =
      Ember.A(quiz_statistics.question_statistics).mapBy('id')

  DS.ActiveModelSerializer.extend
    extractArray: (store, type, payload, id, requestType) ->
      decorate(payload.quiz_statistics[0])

      data = {
        quiz_statistics: payload.quiz_statistics
        question_statistics: payload.quiz_statistics[0].question_statistics
      }

      @_super(store, type, data, id, requestType)