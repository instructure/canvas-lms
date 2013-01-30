define [
  'jquery'
  'compiled/views/ValidatedFormView'
  'jst/DialogFormWrapper'
  'jqueryui/dialog'
], ($, ValidatedFormView, wrapper) ->

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
    # @api private
    setTrigger: ->
      return unless @options.trigger
      @$trigger = $ @options.trigger
      @attachTrigger()

    ##
    # @api private
    attachTrigger: ->
      @$trigger.on 'click.dialogFormView', @toggle

    ##
    # @api private
    renderEl: =>
      @$el.html @wrapperTemplate()
      @renderOutlet()
      # reassign: only render the outlout now
      @renderEl = @renderOutlet

    ##
    # @api private
    renderOutlet: =>
      html = @template @model.toJSON()
      @$el.find('.outlet').html html

    ##
    # @api private
    getDialogTitle: ->
      @options.title or
      @$trigger.attr('title') or
      @getAriaTitle()

    getAriaTitle: ->
      ariaID = @$trigger.attr 'aria-describedby'
      $("##{ariaID}").text()

    ##
    # @api private
    setupDialog: ->
      @$el.dialog
        autoOpen: false
        title: @getDialogTitle()
      .fixDialogButtons()
      @dialog = @$el.data 'dialog'

    ##
    # @api private
    onSaveSuccess: =>
      super
      @close()

