define [
  '../start_app',
  'ember',
  'ic-ajax',
  '../../controllers/quizzes_controller',
  '../../models/quiz',
  'ember-data'
  '../environment_setup',
], (startApp, Ember, ajax, QuizzesController, Quiz, DS) ->

  App   = null
  store = null
  {run} = Ember

  module 'quizzes_controller',
    setup: ->
      App = startApp()
      run => @qc = QuizzesController.create()
      container = App.__container__
      store = container.lookup 'store:main'
      quizzes = null
      run =>
        quizzes = Em.A [
            store.createRecord('quiz', {quizType: 'survey', title: 'Test Quiz'}),
            store.createRecord('quiz', {quizType: 'graded_survey', title: 'Test survey'}),
            store.createRecord('quiz', {quizType: 'practice_quiz', title: 'Test practice quiz'}),
            store.createRecord('quiz', {quizType: 'practice_quiz', title: 'Other practice'}),
            store.createRecord('quiz', {quizType: 'assignment', title: 'Assignment test'})
          ]
        @qc.set('model', quizzes)

    teardown: ->
      run =>
        @qc.destroy()
      run App, 'destroy'

  test 'raw quiz types counts calculated correctly', ->
    equal(@qc.get('rawSurveys').length, 2)
    equal(@qc.get('rawPractices').length, 2)
    equal(@qc.get('rawAssignments').length, 1)

  test 'quizzes filters match correctly', ->
    @qc.set('searchFilter', 'quiz')
    equal(@qc.get('surveys').length, 1)
    equal(@qc.get('practices').length, 1)
    equal(@qc.get('assignments').length, 0)

  test 'sorts by sortSlug', ->
    practice = @qc.findBy('title', 'Other practice')
    assignment = @qc.findBy('title', 'Assignment test')
    survey = @qc.findBy('title', 'Test survey')
    run =>
      practice.set 'quizType', 'assignment'
      practice.set 'dueAt', new Date("May 1, 2014")
      assignment.set 'dueAt', new Date("May 2, 2014")
      survey.set 'title', '1AThingThatShouldComeFirstButDoeNot'
      @qc.set 'model', [ assignment, survey, practice ]
    arrangedContent = @qc.get('arrangedContent')
    ok arrangedContent.objectAt(0) is practice
    ok arrangedContent.objectAt(1) is assignment
    ok arrangedContent.objectAt(2) is survey, 'quizzes without due dates come last'
