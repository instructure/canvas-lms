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

  test '#answerSets: it wraps _data.answer_sets as Ember.Objects', ->
    subject.set '_data.answer_sets', [{}]
    ok subject.get('answerSets.firstObject') instanceof Em.Object,
      'it wraps objects'

  test '#ratioCalculator: it builds the ratio calculator', ->
    equal subject.get('ratioCalculator.ratio'), 0