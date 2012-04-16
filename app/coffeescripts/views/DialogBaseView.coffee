define [
  'i18n!dialog'
  'jquery'
  'underscore'
  'Backbone'
], (I18n, $, _, Backbone) ->

  ##
  # A Backbone View to extend for creating a jQuery dialog.
  #
  # Define options for the dialog as an object using the dialogOptions key,
  # those options will be merged with the defaultOptions object.
  # Begin with id and title options.
  class DialogBaseView extends Backbone.View

    initialize: ->
      @initDialog()
      @setElement @dialog

    defaultOptions: ->
      # id:
      # title:
      autoOpen: false
      width: 420
      resizable: false
      buttons: [
        text: I18n.t 'cancel', 'Cancel'
        click: @cancel
      ,
        text: I18n.t 'update', 'Update'
        'class' : 'btn-primary'
        click: @update
      ]

    initDialog: () ->
      opts = _.extend {}, @defaultOptions(), _.result(this, 'dialogOptions')
      @dialog = $("<div id=\"#{ opts.id }\"></div>").appendTo('body').dialog opts

    ##
    # Sample
    #
    # render: ->
    #   @$el.html someTemplate()
    #   this

    show: ->
      @dialog.dialog('open')

    close: ->
      @dialog.dialog('close')

    update: (e) ->
      throw 'Not yet implemented'

    cancel: (e) =>
      e.preventDefault()
      @close()