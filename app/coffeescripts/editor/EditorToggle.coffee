define [
  'underscore'
  'i18n!editor'
  'jquery'
  'Backbone'
  'compiled/fn/preventDefault'
  'compiled/views/editor/KeyboardShortcuts'
  'react'
  'jsx/editor/SwitchEditorControl'
  'jsx/shared/rce/RichContentEditor'
], (_, I18n, $, Backbone, preventDefault, KeyboardShortcuts,
    React, SwitchEditorControl, RichContentEditor) ->

  RichContentEditor.preloadRemoteModule()

  ###
  xsslint safeString.property content
  xsslint safeString.property textArea
  ###

  # Simply returns a unique number with each call
  _nextID = 0
  nextID = ->
    _nextID += 1
    return "editor-toggle-"+_nextID

  ##
  # Toggles an element between a rich text editor and itself
  class EditorToggle

    options:

      # text to display in the "done" button
      doneText: I18n.t 'done_as_in_finished', 'Done'
      # whether or not a "Switch Views" link should be provided to edit the
      # raw html
      switchViews: true

    ##
    # @param {jQueryEl} @el - the element containing html to edit
    # @param {Object} options
    constructor: (elem, options) ->
      @editingElement(elem)
      @options = $.extend {}, @options, options
      @textArea = @createTextArea()
      @textAreaContainer = $('<div/>').append(@textArea)

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
    # Compiles the options for the RichContentEditor
    # @api private
    getRceOptions: ->
      opts = $.extend {
          focus: true,
          tinyOptions: @options.tinyOptions || {}
        }, @options.rceOptions
      if @options.editorBoxLabel
        opts.tinyOptions.aria_label = @options.editorBoxLabel
      opts

    ##
    # Converts the element to an editor
    # @api public
    edit: ->
      @textArea.val @getContent()
      @textAreaContainer.insertBefore @el
      @el.detach()
      if @options.switchViews
        @switchViews = @createSwitchViews()
        @switchViews.insertBefore @textAreaContainer
      @infoIcon ||= (new KeyboardShortcuts()).render().$el
      @infoIcon.css("float", "right")
      @infoIcon.insertAfter @switchViews
      $('<div/>', style: "clear: both").insertBefore @textAreaContainer
      @done.insertAfter @textAreaContainer
      RichContentEditor.initSidebar()
      RichContentEditor.loadNewEditor(@textArea, @getRceOptions())
      @textArea = RichContentEditor.freshNode(@textArea)
      @editing = true
      @trigger 'edit'

    replaceTextArea: ->
      @el.insertBefore @textAreaContainer
      RichContentEditor.destroyRCE(@textArea)
      @textAreaContainer.detach()

    renewTextAreaID: ->
      @textArea.attr 'id', nextID()

    ##
    # Converts the editor to an element
    # @api public
    display: (opts) ->
      if not opts?.cancel
        @content = RichContentEditor.callOnRCE(@textArea, 'get_code')
        @textArea.val @content
        @el.html @content
      @replaceTextArea()
      @switchViews.detach() if @options.switchViews
      @infoIcon.detach()
      @done.detach()
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
        .attr('id',nextID())

    ##
    # creates the "done" button used to exit the editor
    # @api private
    createDone: ->
      $('<div/>').addClass('edit_html_done_wrapper').append(
        $('<a/>')
        .text(@options.doneText)
        .attr('href', '#')
        .addClass('btn edit_html_done')
        .attr('title', I18n.t('done.title', 'Click to finish editing the rich text area'))
        .click preventDefault =>
          @display()
          @editButton?.focus()
      )

    ##
    # create the switch views links to go between rich text and a textarea
    # @api private
    createSwitchViews: ->
      component = React.createElement(SwitchEditorControl, { textarea: @textArea })
      $container = $("<div class='switch-views'></div>")
      React.render(component, $container[0])
      return $container


  _.extend(EditorToggle.prototype, Backbone.Events)

  EditorToggle
