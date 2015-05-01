define [
  'i18n!outcomes'
  'underscore'
  'Backbone'
  'compiled/util/Popover'
  'compiled/views/grade_summary/OutcomeLineGraphView'
  'jst/outcomes/outcomePopover'
], (I18n, _, Backbone, Popover, OutcomeLineGraphView, template) ->
  class OutcomePopoverView extends Backbone.View
    TIMEOUT_LENGTH: 50

    @optionProperty 'el'
    @optionProperty 'model'

    events:
      'click i': 'mouseleave'
      'mouseenter i': 'mouseenter'
      'mouseleave i': 'mouseleave'
    inside: false

    initialize: ->
      super
      @outcomeLineGraphView = new OutcomeLineGraphView({
        model: @model
      })

    # Overrides
    render: ->
      template(@toJSON())

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
      @outcomeLineGraphView.setElement(@popover.el.find("div.line-graph"))
      @outcomeLineGraphView.render()

