define ['i18n!editor', 'jquery', 'tinymce.editor_box'], (I18n, $) ->

  ##
  # Toggles an element between a rich text editor and itself
  class EditorToggle

    options:

      # text to display in the "done" button
      doneText: I18n.t 'done_as_in_finished', 'Done'

    ##
    # @param {jQueryEl} @el - the element containing html to edit
    # @param {Object} options
    constructor: (@el, options) ->
      @options = $.extend {}, @options, options
      @textArea = @createTextArea()
      @done = @createDone()
      @content = @getContent()
      @editing = false

    ##
    # Toggles between editing the content and displaying it
    # @api public
    toggle: ->
      if not @editing
        @edit()
      else
        @display()

    ##
    # Converts the element to an editor
    # @api public
    edit: ->
      @textArea.val @getContent()
      @textArea.insertBefore @el
      @el.detach()
      @done.insertAfter @textArea
      @textArea.editorBox()
      @editing = true

    ##
    # Converts the editor to an element
    # @api public
    display: ->
      @content = @textArea._justGetCode()
      @textArea.val @content
      @el.html @content
      @el.insertBefore @textArea
      @textArea._removeEditor()
      @textArea.detach()
      @done.detach()
      # so tiny doesn't hang on to this instance
      @textArea.attr 'id', ''
      @editing = false

    ##
    # method to get the content for the editor
    # @api private
    getContent: ->
      $.trim @el.html()

    ##
    # creates the textarea tinymce uses for the editor
    # @api private
    createTextArea: ->
      $('<textarea/>')
        .css('width', '100%') # tiny mimics the width of the textarea
        .addClass('editor-toggle')

    ##
    # creates the "done" button used to exit the editor
    # @api private
    createDone: ->
      $('<a/>')
        .html(@options.doneText)
        .addClass('button edit-html-done edit_html_done')
        .click => @display()

