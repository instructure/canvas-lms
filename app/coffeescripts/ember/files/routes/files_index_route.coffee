define ['ember'], (Ember) ->

  IndexRoute = Ember.Route.extend
    beforeModel: ->
      @transitionTo('folder', '')