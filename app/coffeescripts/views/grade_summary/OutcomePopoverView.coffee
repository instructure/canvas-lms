define [
  'i18n!outcomes'
  'underscore'
  'Backbone'
  'compiled/util/Popover'
], (I18n, _, Backbone, Popover) ->

  class OutcomePopoverView extends Backbone.View
    TIMEOUT_LENGTH: 50

    @optionProperty 'el'
    @optionProperty 'model'
    @optionProperty 'template'

    events:
      'keydown' : 'togglePopover'
      'mouseenter': 'mouseenter'
      'mouseleave': 'mouseleave'
    inside: false

    # Overrides
    render: ->
      @template(@toJSON())

    # Instance methods
    closePopover: (e) ->
      e?.preventDefault()
      return true unless @popover?
      @popover.hide()
      delete @popover

    mouseenter: (e) =>
      @openPopover(e)
      @inside  = true

    mouseleave: (e) =>
      @inside  = false
      setTimeout =>
        return if @inside || !@popover
        @closePopover()
      , @TIMEOUT_LENGTH

    openPopover: (e) ->
      if @closePopover()
        @popover = new Popover(e, @render(), {
          verticalSide: 'bottom'
          manualOffset: 14
        })
      @trigger('outcomes:popover:open')

    togglePopover: (e) =>
      keyPressed = @_getKey(e.keyCode)
      if keyPressed == "spacebar"
        @openPopover(e)
      else if keyPressed == "escape"
        @closePopover(e)

    # Private
    _getKey: (keycode) =>
      keys = {
        32 : "spacebar"
        27 : "escape"
      }
      keys[keycode]
