define [
  '../start_app',
  'ember',
  'ic-ajax',
  '../../controllers/quizzes_controller',
  '../environment_setup',
], (startApp, Ember, ajax, QuizzesController) ->

  App = null

  module 'quizzes_controller',
    setup: ->
      App = startApp()
      @qc = new QuizzesController()
      quizzes = Em.A [
          {quiz_type: 'survey', title: 'Test Quiz'},
          {quiz_type: 'graded_survey', title: 'Test survey'},
          {quiz_type: 'practice_quiz', title: 'Test practice quiz'},
          {quiz_type: 'practice_quiz', title: 'Other practice'},
          {quiz_type: 'assignment', title: 'Assignment test'}
        ]
      @qc.set('model', quizzes)

    teardown: ->
      Ember.run App, 'destroy'

  test 'raw quiz types counts calculated correctly', ->
    equal(@qc.get('rawSurveys').length, 2)
    equal(@qc.get('rawPractices').length, 2)
    equal(@qc.get('rawAssignments').length, 1)

  test 'quizzes filters match correctly', ->
    @qc.set('searchFilter', 'quiz')
    equal(@qc.get('surveys').length, 1)
    equal(@qc.get('practices').length, 1)
    equal(@qc.get('assignments').length, 0)

