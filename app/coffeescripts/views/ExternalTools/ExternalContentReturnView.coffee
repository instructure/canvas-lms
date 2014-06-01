define [
  'jquery',
  'jst/ExternalTools/ExternalContentReturnView'
], ($, template) ->

  class ExternalContentReturnView extends Backbone.View
    template: template
    @optionProperty 'launchType'
    @optionProperty 'launchParams'
    @optionProperty 'displayAsModal'

    defaults:
      displayAsModal: true

    els:
      'iframe.tool_launch': "$iframe"

    attach: ->
      @model.on 'change', => @render()

    toJSON: ->
      json = super
      json.launch_url = @model.launchUrl(@launchType, @launchParams)
      json

    afterRender: ->
      @attachLtiEvents()
      settings = @model.get(@launchType) || {}
      @$iframe.width '100%'
      @$iframe.height settings.selection_height
      if @displayAsModal
        @$el.dialog
          title: @model.get(@launchType)?.label || ''
          width: settings.selection_width
          height: settings.selection_height
          resizable: true
          close: @removeDialog

    attachLtiEvents: ->
      $(window).on 'externalContentReady', @_contentReady
      $(window).on 'externalContentCancel', @_contentCancel

    detachLtiEvents: ->
      $(window).off 'externalContentReady', @_contentReady
      $(window).off 'externalContentCancel', @_contentCancel

    removeDialog: =>
      @detachLtiEvents()
      @remove()

    _contentReady: (event, data) =>
      @trigger 'ready', data
      @removeDialog()

    _contentCancel: (event, data) =>
      @trigger 'cancel', data
      @removeDialog()
