define [
  '../start_app',
  'ember',
  'ic-ajax',
  '../../shared/environment',
  '../../controllers/quizzes_controller'
], (startApp, Ember, ajax, environment, QuizzesController) ->

  App = null

  window.ENV = {
    context_asset_string: 'course_1'
  }

  module 'quizzes_controller',
    setup: ->
      App = startApp()
      @qc = new QuizzesController()
      @qc.set('model', [
        {quiz_type: 'survey', title: 'Test Quiz'},
        {quiz_type: 'graded_survey', title: 'Test survey'},
        {quiz_type: 'practice_quiz', title: 'Test practice quiz'},
        {quiz_type: 'practice_quiz', title: 'Other practice'},
        {quiz_type: 'assignment', title: 'Assignment test'}
      ])

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

