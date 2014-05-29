define [
  'ember'
  'ember-data'
  'i18n!quiz_statistics'
  '../shared/util'
], (Ember, DS, I18n, Util) ->
  {round} = Util
  participantCount = 0

  calculateResponseRatio = (answer) ->
    if participantCount > 0 # guard against div by zero
      round(answer.responses / participantCount * 100)
    else
      0

  decorate = (quiz_statistics) ->
    participantCount = quiz_statistics.submission_statistics.unique_count

    quiz_statistics.question_statistics.forEach (question_statistics) ->
      question_statistics.id = "#{question_statistics.id}"

      # assign a FK between question and quiz statistics
      question_statistics.quiz_statistics_id = quiz_statistics.id

      decorateAnswers(question_statistics.answers)

      if question_statistics.answer_sets
        question_statistics.answer_sets.forEach(decorateAnswerSet)

    # set of FKs between quiz and question stats
    quiz_statistics.question_statistics_ids =
      Ember.A(quiz_statistics.question_statistics).mapBy('id')

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
    (answerSet.answers || []).forEach (answer, i) ->
      answer.ratio = calculateResponseRatio(answer)

      if answer.id == 'none'
        answer.text = I18n.t('no_answer', 'No Answer')
      else if answer.id == 'other'
        answer.text = I18n.t('unknown_answer', 'Something Else')

  DS.ActiveModelSerializer.extend
    extractArray: (store, type, payload, id, requestType) ->
      decorate(payload.quiz_statistics[0])

      data = {
        quiz_statistics: payload.quiz_statistics
        question_statistics: payload.quiz_statistics[0].question_statistics
      }

      @_super(store, type, data, id, requestType)