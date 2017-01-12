define [
  'i18n!editor'
  'jquery'
  'compiled/editor/EditorToggle'
  'compiled/str/apiUserContent'
  'vendor/jquery.ba-tinypubsub'
  'jsx/shared/rce/RichContentEditor'
], (I18n, $, EditorToggle, apiUserContent, {publish}, RichContentEditor) ->

  ###
  xsslint safeString.property content
  ###

  # Simply returns a unique number with each call
  _nextID = 0
  nextID = ->
    _nextID += 1
    return "editor-toggle-"+_nextID

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
      super @getEditingElement(),
        switchViews: true
        rceOptions: {manageParent: true}
      @cancelButton = @createCancelButton()
      @done.addClass 'btn-small'

    ##
    # Overwrites parent and will be called by parent's display.
    # Handles the problem of not having the correct reference to
    # the textArea on the page when using RCS.
    replaceTextArea: ->
      newTextArea = RichContentEditor.freshNode(@textArea)
      @el.insertBefore newTextArea
      RichContentEditor.destroyRCE(@textArea)
      newTextArea.detach()

    ##
    # Overwrites parent and will be called by parent's display.
    # Makes sure the textArea reference has an ID (apparently
    # tinyMCE will hold on to it otherwise)
    renewTextAreaID: ->
      @textArea.attr 'id', nextID()

    ##
    # Extends EditorToggle::display to save the model's message.
    #
    # @param {Bool} opts.cancel - doesn't submit
    # @api public
    display: (opts) ->
      super opts
      @cancelButton.detach()
      if opts?.cancel isnt true
        @view.model.set('updated_at', (new Date).toISOString())
        @view.model.set('editor', ENV.current_user)
        @view.model.save
          messageNotification: I18n.t('saving', 'Saving...')
          message: @content
        ,
          success: @onSaveSuccess
          error: @onSaveError

    ##
    # Makes sure the textarea has an id
    # @api private
    createTextArea: ->
      result = super
      if result.attr('id')
        result
      else
        result.attr('id',nextID())

    createCancelButton: ->
      $('<a/>')
        .text(I18n.t('cancel', 'Cancel'))
        .css(marginLeft: '5px')
        .attr('href', 'javascript:')
        .addClass('cancel_button')
        .click => @display cancel: true

    edit: ->
      @editingElement(@getEditingElement())
      super
      @cancelButton.insertAfter @done

    ##
    # Get the jQueryEl element on the discussion entry to edit.
    #
    # @api private
    getEditingElement: ->
      @view.$('.message:first')

    ##
    # Overrides EditorToggle::getContent to get the content from the model
    # rather than the HTML of the element. This is because `enhanceUserContent`
    # in `instructure.js` manipulates the html and we need the raw html.
    #
    # @api private
    getContent: ->
      apiUserContent.convert @view.model.get('message'), forEditing: true

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
      @view.model.set
        messageNotification: I18n.t('save_failed', 'Failed to save, please try again later')
      @edit()
