define [
  'Backbone'
], (Backbone) ->

  class SpeedgraderLinkView extends Backbone.View

    initialize: ->
      super
      @model.on 'change:published', @toggleSpeedgraderLink

    toggleSpeedgraderLink: =>
      if @model.get 'published'
        @$el.removeClass 'hidden'
      else
        @$el.addClass 'hidden'

