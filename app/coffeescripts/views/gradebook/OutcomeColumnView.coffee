define [
  'i18n!gradebook2'
  'Backbone'
  'compiled/util/Popover'
  'jst/gradebook2/outcome_popover'
], (I18n, {View}, Popover, popover_template) ->

  class OutcomeColumnView extends View

    popover_template: popover_template

    @optionProperty 'totalsFn'

    inside: false

    TIMEOUT_LENGTH: 50

    events:
      mouseenter: 'mouseenter'
      mouseleave: 'mouseleave'

    createPopover: (e) ->
      @totalsFn()
      popover = new Popover(e, @popover_template(@attributes))
      popover.el.on('mouseenter', @mouseenter)
      popover.el.on('mouseleave', @mouseleave)
      popover.show(e)
      popover

    mouseenter: (e) =>
      @popover = @createPopover(e) unless @popover
      @inside  = true

    mouseleave: (e) =>
      @inside  = false
      setTimeout =>
        return if @inside || !@popover
        @popover.hide()
        delete @popover
      , @TIMEOUT_LENGTH
