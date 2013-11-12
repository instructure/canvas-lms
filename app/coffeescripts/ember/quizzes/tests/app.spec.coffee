define ['./app', 'ember'], (App, Ember) ->

  module 'quizzes', ->
    setup: ->
      App.reset()
      Ember.run(App, App.advanceReadiness)

  test 'says hello', ->
    visit('/').then ->
      equal(find('h1').html().trim(), 'Fabulous Ember Quizzes')

