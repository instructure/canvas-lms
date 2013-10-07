define [
  'ember'
], (Ember) ->
  Ember.Route.extend
    redirect: ->
      # Ember.debug('404 :: redirection to index');
      this.transitionTo ''
