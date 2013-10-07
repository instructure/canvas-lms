define [
  'Backbone'
  'compiled/views/VddTooltipView'
  'compiled/models/Assignment'
  'jquery'
  'helpers/jquery.simulate'
], (Backbone, VddTooltipView, Assignment, $) ->

  module 'VddTooltipView',
    setup: ->
      @model = new Assignment(id: 1, html_url: 'http://example.com')
      @tooltipView = new VddTooltipView(model: @model)

  test 'initializes json variables', ->
    @tooltipView.render()

    json = @tooltipView.toJSON()
    equal     json['selector'], "1"
    equal     json['linkHref'], "http://example.com"
    deepEqual json['allDates'], []

  test 'initializes tooltip', ->
    sinon.spy $.fn, "tooltip"

    @tooltipView.render()

    ok $.fn.tooltip.called
    $.fn.tooltip.restore()
