define [
  'ember'
  '../../start_app'
  '../../environment_setup'
  '../../../models/question_statistics/response_ratio_calculator'
], (Ember, startApp, env, ResponseRatioCalculator) ->

  {run} = Ember
  App = null
  subject = null

  module 'ResponseRatioCalculator',
    setup: ->
      App = startApp()
      subject = ResponseRatioCalculator.create({
        content: {},
        quizStatistics: {}
      })

    teardown: ->
      run App, 'destroy'

  test 'should run', ->
    ok true

  test '#ratio: happy path', ->
    run ->
      subject.set 'participantCount', 10

      subject.set 'answerPool', [{ id: 1, responses: 0, correct: true }]
      equal subject.get('ratio'), 0

      subject.set 'answerPool', [{ id: 1, responses: 3, correct: true }]
      equal subject.get('ratio'), 0.3

      subject.set 'answerPool', [{ id: 1, responses: 10, correct: true }]
      equal subject.get('ratio'), 1

  test '#ratio: doesnt divide by zero', ->
    run ->
      subject.set 'participantCount', 0
      subject.set 'answerPool', [{ id: 1, responses: 2, correct: true }]
      equal subject.get('ratio'), 0


  test '#correctMultipleResponseRatio', ->
    run ->
      subject.set 'questionType', 'multiple_answers_question'
      subject.set 'participantCount', 10
      subject.set 'answerPool', [
        { user_ids: [3], correct: true },
        { user_ids: [ ], correct: false },
        { user_ids: [3], correct: true },
      ]

      equal subject.get('ratio'), 0.1,
        'it counts only students who have picked all correct answers and nothing else'

      subject.set 'answerPool', [
        { user_ids: [3], correct: true },
        { user_ids: [3], correct: false },
        { user_ids: [3], correct: true },
      ]

      equal subject.get('ratio'), 0,
        "it doesn't count students who picked a wrong answer and a correct one"



