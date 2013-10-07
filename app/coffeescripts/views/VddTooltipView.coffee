define [
  'i18n!assignments'
  'Backbone'
  'jst/VddTooltipView'
  'jquery'
  'compiled/behaviors/tooltip'
], (I18n, Backbone, template, $) ->

  class VddTooltipView extends Backbone.View
    template: template

    els:
      '.vdd_tooltip_link': '$link'

    afterRender: ->
      @$link.tooltip
        position: {my: 'center bottom', at: 'center top-10', collision: 'fit fit'},
        tooltipClass: 'center bottom vertical',
        content: -> $($(@).data('tooltipSelector')).html()

    toJSON: ->
      base = super
      base.selector = @model.get("id")
      base.linkHref = @model.htmlUrl()
      base.allDates = @model.allDates()
      base
