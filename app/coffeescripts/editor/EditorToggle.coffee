define [
  'underscore'
  'i18n!editor'
  'jquery'
  'Backbone'
  'compiled/fn/preventDefault'
  'tinymce.editor_box'
], (_, I18n, $, Backbone, preventDefault) ->

  ##
  # Toggles an element between a rich text editor and itself
  class EditorToggle

    options:

      # text to display in the "done" button
      doneText: I18n.t 'done_as_in_finished', 'Done'
      # whether or not a "Switch Views" link should be provided to edit the
      # raw html
      switchViews: false

    ##
    # @param {jQueryEl} @el - the element containing html to edit
    # @param {Object} options
    constructor: (elem, options) ->
      @editingElement(elem)
      @options = $.extend {}, @options, options
      @textArea = @createTextArea()
      @switchViews = @createSwitchViews() if @options.switchViews
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
      @switchViews.insertBefore @textArea if @options.switchViews
      @done.insertAfter @textArea
      if @options.editorBoxLabel
        opts = tinyOptions: {aria_label: @options.editorBoxLabel}
      @textArea.editorBox opts
      @editing = true
      @trigger 'edit'

    ##
    # Converts the editor to an element
    # @api public
    display: (opts) ->
      if not opts?.cancel
        @content = @textArea._justGetCode()
        @textArea.val @content
        @el.html @content
      @el.insertBefore @textArea
      @textArea._removeEditor()
      @textArea.detach()
      @switchViews.detach() if @options.switchViews
      @done.detach()
      # so tiny doesn't hang on to this instance
      @textArea.attr 'id', ''
      @editing = false
      @trigger 'display'

    ##
    # Assign/re-assign the jQuery element to to edit.
    #
    # @param {jQueryEl} @el - the element containing html to edit
    # @api public
    editingElement: (elem)->
      @el = elem

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
        # tiny mimics the width of the textarea. its min height is 110px, so
        # we want the textarea at least that big as well
        .css(width: '100%', minHeight: '110px')
        .addClass('editor-toggle')

    ##
    # creates the "done" button used to exit the editor
    # @api private
    createDone: ->
      $('<a/>')
        .html(@options.doneText)
        .attr('href', '#')
        .addClass('btn edit-html-done edit_html_done')
        .attr('title', I18n.t('done.title', 'Click to finish editing the rich text area'))
        .click preventDefault => @display()

    ##
    # create the switch views link to go between rich text and a textarea
    # @api private
    createSwitchViews: ->
      $('<a/>', style: "float: right", href: "#")
        .text(I18n.t('switch_views', 'Switch Views'))
        .click preventDefault => @textArea.editorBox('toggle')


  _.extend(EditorToggle.prototype, Backbone.Events)

  EditorToggle
