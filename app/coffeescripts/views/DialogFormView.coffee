define [
  'jquery'
  'compiled/views/ValidatedFormView'
  'i18n!contextual_settings'
  'jst/DialogFormWrapper'
  'jqueryui/dialog'
], ($, ValidatedFormView, I18n, wrapper) ->

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
      # the element selector that opens the dialog
      trigger: '.dialogFormTrigger'

    $dialogAppendTarget: $ 'body'

    className: 'dialogFormView'

    ##
    # creates the form wrapper, with generic “save” and “cancel” buttons,
    # override in subclasses at will
    wrapperTemplate: wrapper

    initialize: ->
      super
      @setTrigger()
      @attachTrigger()

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
      if @dialog?.isOpen() then @close() else @open()

    ##
    # @api public
    remove: ->
      super
      @$trigger.off '.dialogFormView'

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

    ##
    # @api private
    insert: ->
      @$el.appendTo @$dialogAppendTarget

    ##
    # @api private
    setTrigger: ->
      @$trigger = $ @options.trigger

    ##
    # @api private
    attachTrigger: ->
      @$trigger.on 'click.dialogFormView', @toggle

    ##
    # @api private
    renderEl: =>
      @$el.html @wrapperTemplate()
      @renderOutlet()
      # reassign: only render the outlout to subsequent calls to render
      @renderEl = @renderOutlet

    ##
    # @api private
    renderOutlet: =>
      html = @template @model.toJSON()
      @$el.find('.outlet').html html

    ##
    # @api private
    getDialogTitle: ->
      @$trigger.attr 'title'

    ##
    # @api private
    setupDialog: ->
      @$el.dialog
        autoOpen: false
        title: @getDialogTitle()
      @dialog = @$el.data 'dialog'

    ##
    # @api private
    onSaveSuccess: =>
      super
      @close()

