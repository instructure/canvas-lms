define [
  'jquery'
  'compiled/views/ValidatedFormView'
  'compiled/fn/preventDefault'
  'jst/DialogFormWrapper'
  'jqueryui/dialog'
  'compiled/jquery/fixDialogButtons'
], ($, ValidatedFormView, preventDefault, wrapper) ->

  ##
  # Creates a form dialog.
  #
  # - Wraps your template in a form (don't need a form tag or button controls
  #   in the template)
  #
  # - Handles saving the model to the server
  #
  # usage:
  #
  #   handlebars:
  #     <p>
  #       <label><input name="first_name" value="{{first_name}}"/></label>
  #     </p>
  #
  #   coffeescript:
  #     new DialogFormView
  #       template: someTemplate
  #       model: someModel
  #       trigger: '#editSettings'
  #
  class DialogFormView extends ValidatedFormView

    defaults:

      ##
      # the element selector that opens the dialog, if false, no trigger logic
      # will be established
      trigger: false

      ##
      # will figure out the title from the trigger if null
      title: null

      width: null

      height: null

      minWidth: null

      minHeight: null

      fixDialogButtons: true

    $dialogAppendTarget: $ 'body'

    className: 'dialogFormView'

    ##
    # creates the form wrapper, with button controls
    # override in subclasses at will
    wrapperTemplate: wrapper

    initialize: ->
      super
      @setTrigger()
      @open = @firstOpen
      @renderEl = @firstRenderEl

    ##
    # the function to open the dialog.  will be set to either @firstOpen or
    # @openAgain depending on the state of the view
    #
    # @api public
    open: null

    ##
    # @api public
    close: ->
      # could be calling this from the close event
      # so we want to check if it's open
      if @dialog?.isOpen()
        @dialog.close()
      @focusReturnsTo()?.focus()

    ##
    # @api public
    toggle: =>
      if @dialog?.isOpen()
        @close()
      else
        @open()

    ##
    # @api public
    remove: ->
      super
      @$trigger?.off '.dialogFormView'
      @$dialog?.remove()
      @open = @firstOpen
      @renderEl = @firstRenderEl

    ##
    # lazy init on first open
    # @api private
    firstOpen: ->
      @insert()
      @render()
      @setupDialog()
      @openAgain()
      @open = @openAgain

    ##
    # @api private
    openAgain: ->
      @dialog.open()
      @dialog.uiDialog.focus()

    ##
    # @api private
    insert: ->
      @$el.appendTo @$dialogAppendTarget

    ##
    # If your trigger isn't rendered after this view (like a parent view
    # contains the trigger) then you can set this manually (like in the
    # parent views afterRender), otherwise it'll use the options.
    #
    # @api public
    #
    setTrigger: (el) ->
      @options.trigger = el if el
      return unless @options.trigger
      @$trigger = $ @options.trigger
      @attachTrigger()

    ##
    # @api private
    attachTrigger: ->
      @$trigger?.on 'click.dialogFormView', preventDefault(@toggle)

    ##
    # the function to render the element.  it will either be firstRenderEl or
    # renderElAgain depending on the state of the view
    #
    # @api private
    renderEl: null

    firstRenderEl: =>
      @$el.html @wrapperTemplate @toJSON()
      @renderElAgain()
      # reassign: only render the outlet now
      @renderEl = @renderElAgain

    ##
    # @api private
    renderElAgain: =>
      html = @template @toJSON()
      @$el.find('.outlet').html html

    ##
    # @api private
    getDialogTitle: ->
      @options.title or
      @$trigger?.attr('title') or
      @getAriaTitle()

    getAriaTitle: ->
      ariaID = @$trigger?.attr 'aria-describedby'
      $("##{ariaID}").text()

    ##
    # @api private
    setupDialog: ->
      opts =
        autoOpen: false
        title: @getDialogTitle()
        close: =>
          @close()
          @trigger 'close'
        open: => @trigger 'open'
      opts.width = @options.width
      opts.height = @options.height
      opts.minWidth = @options.minWidth
      opts.minHeight = @options.minHeight
      @$el.dialog(opts)
      @$el.fixDialogButtons() if @options.fixDialogButtons
      @dialog = @$el.data 'dialog'
      $('.ui-resizable-handle').attr('aria-hidden', true)

    setDimensions: (width, height) ->
      width = if width? then width else @options.width
      height = if height? then height else @options.height
      opts =
        width: width
        height: height
      @$el.dialog(opts)

    ##
    # @api private
    onSaveSuccess: =>
      super
      @close()

    ##
    # @api private
    focusReturnsTo: ->
      return null unless @$trigger
      if id = @$trigger.data('focusReturnsTo')
        return $("##{id}")
      else
        return @$trigger
