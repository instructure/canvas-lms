define [
  'ember'
], (Ember) ->
  # Paints the screen with a dark overlay containing a loading spinner. Useful
  # for cross-section transitions.
  #
  # The mixin will do nothing if we're transitioning away from the Loading
  # route.
  Ember.Mixin.create
    actions:
      loading: (transition) ->
        inLoadingRoute = transition.router.currentHandlerInfos.some (handler) ->
          handler.name == 'loading'

        unless inLoadingRoute
          Ember.$('body').addClass('ember-loading-overlay')

          transition.promise.finally ->
            Ember.$('body').removeClass('ember-loading-overlay')

        return true