define [
  'i18n!editor'
  'jquery'
  'compiled/editor/EditorToggle'
], (I18n, $, EditorToggle) ->

  ##
  # Makes an EntryView's model message editable with TinyMCE
  #
  # ex:
  #
  #   editor = new EntryEditor(EntryView)
  #   editor.edit()    # turns the content into a TinyMCE editor box
  #   editor.display() # closes editor, saves model
  #
  class EntryEditor extends EditorToggle

    ##
    # @param {EntryView} view
    constructor: (@view) ->
      super @view.$('.message:first')

    ##
    # Extends EditorToggle::display to save the model's message.
    #
    # @api public
    display: ->
      super
      @view.model.save
        messageNotification: I18n.t('saving', 'Saving...')
        message: @content
      ,
        success: @onSaveSuccess
        error: @onSaveError
    ##
    # Overrides EditorToggle::getContent to get the content from the model
    # rather than the HTML of the element. This is because `enhanceUserContent`
    # in `instructure.js` manipulates the html and we need the raw html.
    #
    # @api private
    getContent: ->
      @view.model.get 'message'

    ##
    # Called when the model is successfully saved, provides user feedback
    #
    # @api private
    onSaveSuccess: =>
      @view.model.set 'messageNotification', ''

    ##
    # Called when the model fails to save, provides user feedback
    #
    # @api private
    onSaveError: =>
      console.log 'error'
      @view.model.set
        messageNotification: I18n.t('save_failed', 'Failed to save, please try again later')
      @edit()

