define [
  'ember'
  'ember-qunit'
  '../start_app'
  '../environment_setup'
], (Em, emq, startApp) ->

  {run} = Em
  App = null
  subject = null

  module 'QuestionStatistics',
    setup: ->
      App = startApp()
      run ->
        store = App.__container__.lookup 'store:main'
        subject = store.createRecord 'question_statistics'
        subject.set 'quizStatistics', store.createRecord('quiz_statistics', {
          submissionStatistics: {}
        })

    teardown: ->
      run App, 'destroy'

  test 'should run', ->
    ok true

  test '#correctResponseRatio: happy path', ->
    run ->
      subject.set 'quizStatistics.submissionStatistics.unique_count', 10

      subject.set 'answers', [{ id: 1, responses: 0, correct: true }]
      equal subject.get('correctResponseRatio'), 0

      subject.set 'answers', [{ id: 1, responses: 3, correct: true }]
      equal subject.get('correctResponseRatio'), 0.3

      subject.set 'answers', [{ id: 1, responses: 10, correct: true }]
      equal subject.get('correctResponseRatio'), 1

  test '#correctResponseRatio: doesnt divide by zero', ->
    run ->
      subject.set 'quizStatistics.submissionStatistics.unique_count', 0
      subject.set 'answers', [{ id: 1, responses: 2, correct: true }]
      equal subject.get('correctResponseRatio'), 0


  test '#correctMultipleResponseRatio', ->
    run ->
      sinon.stub(subject, 'hasMultipleAnswers').returns(true)
      subject.set 'quizStatistics.submissionStatistics.unique_count', 10
      subject.set 'answers', [
        { user_ids: [3], correct: true },
        { user_ids: [ ], correct: false },
        { user_ids: [3], correct: true },
      ]

      equal subject.get('correctResponseRatio'), 0.1,
        'it counts only students who have picked all correct answers and nothing else'

      subject.set 'answers', [
        { user_ids: [3], correct: true },
        { user_ids: [3], correct: false },
        { user_ids: [3], correct: true },
      ]

      equal subject.get('correctResponseRatio'), 0,
        "it doesn't count students who picked a wrong answer and a correct one"



