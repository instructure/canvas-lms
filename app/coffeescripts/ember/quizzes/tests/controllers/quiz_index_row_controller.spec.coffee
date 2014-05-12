define [
  '../start_app',
  'ember',
  'ic-ajax',
  '../../controllers/quiz_index_row_controller',
  '../environment_setup',
], (startApp, Ember, ajax, QuizIndexRowController) ->

  App = null
  {run} = Ember

  module 'quizzes_controller',
    setup: ->
      App = startApp()
      cont = App.__container__
      store = cont.lookup('store:main')
      run =>
        @qc = QuizIndexRowController.create
          controllers:
            quizzes: Em.ObjectController
        @model = store.createRecord 'quiz',
          pointsPossible: 1
          title: 'Assignment test'
          htmlURL: 'foo/bar'
        @qc.set('model', @model)

    teardown: ->
      Ember.run App, 'destroy'

  test 'display singular points possible', ->
    equal(@qc.get('pointsPossible'), '1 pt')

  test 'display mulitple points possible', ->
    run => @model.set('pointsPossible', 2)
    equal(@qc.get('pointsPossible'), '2 pts')

  test 'doesnt display when zero points possible', ->
    run => @model.set('pointsPossible', 0)
    equal(@qc.get('pointsPossible'), '')

  test 'doesnt display when undefined points possible', ->
    run => @model.set('pointsPossible', undefined)
    equal(@qc.get('pointsPossible'), '')

  test 'correctly creates edit url for quiz', ->
    equal(@qc.get('editUrl'), 'foo/bar/edit')
