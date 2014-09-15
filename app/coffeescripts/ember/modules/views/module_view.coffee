define [
  'ember'
], (Ember) ->

  ModuleView = Ember.View.extend

    animateOnDestroy: (->
      return unless @get('controller.isDeleting')
      @$().fadeOut(175)
    ).observes('controller.isDeleting')

