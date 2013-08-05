define [
  'jquery'
  'compiled/views/ValidatedFormView'
  'compiled/fn/preventDefault'
  'jst/DialogFormWrapper'
  'jqueryui/dialog'
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

    ##
    # @api public
    open: ->
      @firstOpen()
      @openAgain()
      @open = @openAgain

    ##
    # @api public
    close: ->
      @dialog.close()
      @$trigger?.focus()

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

    ##
    # lazy init on first open
    # @api private
    firstOpen: ->
      @insert()
      @render()
      @setupDialog()

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
    # @api private
    renderEl: =>
      @$el.html @wrapperTemplate @toJSON()
      @renderOutlet()
      # reassign: only render the outlout now
      @renderEl = @renderOutlet

    ##
    # @api private
    renderOutlet: =>
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
        close: => @trigger 'close'
        open: => @trigger 'open'
      opts.width = @options.width
      opts.height = @options.height
      @$el.dialog(opts)
      @$el.fixDialogButtons() if @options.fixDialogButtons
      @dialog = @$el.data 'dialog'

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

