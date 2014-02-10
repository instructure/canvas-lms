define [
  '../start_app',
  'ember',
  'ic-ajax',
  '../../controllers/quiz_controller',
  '../environment_setup',
], (startApp, Ember, ajax, QuizController) ->

  App = null

  module 'quizzes_controller',
    setup: ->
      App = startApp()
      cont = new Em.Container()
      cont.register('controller:quizzes', Em.Object)
      @qc = App.QuizController.create({container: cont})
      @qc.set('model', {points_possible: 1, title: 'Assignment test'})

    teardown: ->
      Ember.run App, 'destroy'

  test 'display singular points possible', ->
    equal(@qc.get('pointsPossible'), '1 pt')

  test 'display mulitple points possible', ->
    @qc.set('model', {points_possible: 2, title: 'Assignment test'})
    equal(@qc.get('pointsPossible'), '2 pts')

  test 'doesnt display when zero points possible', ->
    @qc.set('model', {points_possible: 0, title: 'Assignment test'})
    equal(@qc.get('pointsPossible'), '')

  test 'doesnt display when undefined points possible', ->
    @qc.set('model', {title: 'Assignment test'})
    equal(@qc.get('pointsPossible'), '')
