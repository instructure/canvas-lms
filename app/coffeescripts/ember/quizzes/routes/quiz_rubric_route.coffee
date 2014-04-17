define [
  'ember'
], (Em) ->

  Em.Route.extend
    model: ->
      @modelFor 'quiz'
