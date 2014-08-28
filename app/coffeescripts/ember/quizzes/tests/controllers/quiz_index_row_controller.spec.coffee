define [
  '../start_app'
  'ember'
  '../../controllers/quiz_index_row_controller'
  'ember-qunit'
  '../environment_setup'
], (startApp, Ember, QuizIndexRowController, emq) ->

  {run} = Ember

  App = startApp()
  emq.setResolver(Ember.DefaultResolver.create({namespace: App}))

  emq.moduleFor('controller:quiz_index_row', 'QuizIndexRowController', {
    needs: ['controller:quizzes']
    setup: ->
      App = startApp()
      emq.setResolver(Ember.DefaultResolver.create({namespace: App}))
      @model = Ember.Object.create
        pointsPossible: 1
        title: 'Assignment test'
        htmlURL: 'foo/bar'
      @qc = this.subject()
      @qc.set('model', @model)
    teardown: ->
      run App, 'destroy'
    }
  )

  emq.test 'sanity', ->
    ok(@qc)

  emq.test 'display singular points possible', ->
    equal(@qc.get('pointsPossible'), '1 pt')

  emq.test 'display mulitple points possible', ->
    run => @model.set('pointsPossible', 2)
    equal(@qc.get('pointsPossible'), '2 pts')

  emq.test 'doesnt display when zero points possible', ->
    run => @model.set('pointsPossible', 0)
    equal(@qc.get('pointsPossible'), '')

  emq.test 'doesnt display when undefined points possible', ->
    run => @model.set('pointsPossible', undefined)
    equal(@qc.get('pointsPossible'), '')

  emq.test 'correctly creates edit url for quiz', ->
    equal(@qc.get('editUrl'), 'foo/bar/edit')
