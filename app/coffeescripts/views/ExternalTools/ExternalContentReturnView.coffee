define [
  'jquery',
  'jst/ExternalTools/ExternalContentReturnView'
], ($, template) ->

  class ExternalContentReturnView extends Backbone.View
    template: template
    @optionProperty 'launchType'
    @optionProperty 'launchParams'

    els:
      'iframe.tool_launch': "$iframe"

    attach: ->
      @model.on 'change', => @render()
      $(window).one 'externalContentReady', @_contentReady
      $(window).one 'externalContentCancel', @_contentCancel

    toJSON: ->
      json = super
      json.launch_url = @model.launchUrl(@launchType, @launchParams)
      json

    afterRender: ->
      #need to rework selection_height/width to be inclusive of cascading values
      settings = @model.get(@launchType) || {}
      @$iframe.width settings.selection_width
      @$iframe.height settings.selection_height
      @$el.dialog
        title: 'Tool name'
        width: settings.selection_width
        height: settings.selection_height
        resizable: true
        close: =>
          @remove()

    _contentReady: (event, data) =>
      @trigger 'ready', data
      @remove()

    _contentCancel: (event, data) =>
      @trigger 'cancel', data
      @remove()
