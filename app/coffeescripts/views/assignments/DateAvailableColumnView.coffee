define [
  'i18n!assignments'
  'Backbone'
  'jst/assignments/DateAvailableColumnView'
  'jquery'
  'underscore'
  'compiled/behaviors/tooltip'
], (I18n, Backbone, template, $, _) ->

  class DateAvailableColumnView extends Backbone.View
    template: template

    els:
      '.vdd_tooltip_link': '$link'

    afterRender: ->
      @$link.tooltip
        position: {my: 'center bottom', at: 'center top-10', collision: 'fit fit'},
        tooltipClass: 'center bottom vertical',
        content: -> $($(@).data('tooltipSelector')).html()

    toJSON: ->
      group = @model.defaultDates()

      data = @model.toView()
      data.defaultDates = group.toJSON()
      data.canManage    = @canManage()
      data.selector     = @model.get("id") + "_lock"
      data.linkHref     = @model.htmlUrl()
      data.allDates     = @model.allDates()
      data

    canManage: ->
      ENV.PERMISSIONS.manage