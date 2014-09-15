define [
  'ember'
], (Ember) ->

  ModuleView = Ember.View.extend

    tagName: 'li'

    animateOnDestroy: (->
      return unless @get('controller.isDeleting')
      @$().slideToggle(350)
    ).observes('controller.isDeleting')

