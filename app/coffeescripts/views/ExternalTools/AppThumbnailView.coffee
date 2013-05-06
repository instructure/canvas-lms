define [
  'Backbone'
  'jst/ExternalTools/AppThumbnailView'
], (Backbone, template) ->

  class AppThumbnailView extends Backbone.View
    template: template
    className: 'app'

    events:
      'mouseenter': 'showDetails'
      'mouseleave': 'hideDetails'
      'click': 'hideDetails'

    initialize: ->
      super
      @isHidingDetails = true

    showDetails: =>
      if @isHidingDetails
        @$('.details').fadeTo 200, .85
        @isHidingDetails = false

    hideDetails: =>
      @$('.details').fadeOut 200, =>
        @isHidingDetails = true
