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
      @cancelButton = @createCancelButton()
      @$delAttachmentButton = @createDeleteAttachmentButton()
      @done.addClass 'btn-small'

    ##
    # Extends EditorToggle::display to save the model's message.
    #
    # @param {Bool} opts.cancel - doesn't submit
    # @api public
    display: (opts) ->
      super opts
      @cancelButton.detach()
      @$delAttachmentButton.detach()
      if opts?.cancel isnt true
        if @remove_attachment
          @view.model.set('attachments', null)
          @view.model.set('attachment', null)

        @view.model.set('updated_at', (new Date).toISOString())
        @view.model.set('editor', ENV.current_user)

        @view.model.save
          messageNotification: I18n.t('Saving...')
          message: @content
        ,
          success: @onSaveSuccess
          error: @onSaveError
      else
        @getAttachmentElement().show()  # may have been hidden if user deleted attachment then cancelled

    createCancelButton: ->
      $('<a/>')
        .text(I18n.t('Cancel'))
        .css(marginLeft: '5px')
        .attr('href', 'javascript:')
        .addClass('cancel_button')
        .click => @display cancel: true

    createDeleteAttachmentButton: ->
      $('<a/>')
        .attr('href', 'javascript:')
        .text('x')
        .addClass('cancel_button')
        .attr('aria-label', I18n.t('Remove Attachment'))
        # fontSize copied from discussions_edit so it looks like the main topic
        .css(
          float: 'none'
          marginLeft: '.5em'
          fontSize: '20px'
          fontSize: '1.25rem'
        )
        .click => @delAttachment()

    edit: ->
      @editingElement(@getEditingElement())
      super
      @cancelButton.insertAfter @done
      @getAttachmentElement().append(@$delAttachmentButton)

    ##
    # sets a flag telling us to remove the entry's attachment
    # then hides the attachment's UI bits. We do this in lieu of removing
    delAttachment: ->
      @remove_attachment = true
      @getAttachmentElement().hide()

    ##
    # Get the jQueryEl element on the discussion entry to edit.
    #
    # @api private
    getEditingElement: ->
      @view.$('.message:first')

    ##
    # Get the jQuery element on the attachment as shown in the entry
    #
    # @api private
    getAttachmentElement: ->
      @view.$('article:first .comment_attachments > div')

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
      @view.render()

    ##
    # Called when the model fails to save, provides user feedback
    #
    # @api private
    onSaveError: =>
      @view.model.set
        messageNotification: I18n.t('Failed to save, please try again later')
      @edit()
