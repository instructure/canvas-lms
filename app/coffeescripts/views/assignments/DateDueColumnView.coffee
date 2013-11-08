define [
  'i18n!assignments'
  'Backbone'
  'jst/assignments/DateDueColumnView'
  'jquery'
  'compiled/behaviors/tooltip'
], (I18n, Backbone, template, $) ->

  class DateDueColumnView extends Backbone.View
    template: template

    els:
      '.vdd_tooltip_link': '$link'

    afterRender: ->
      @$link.tooltip
        position: {my: 'center bottom', at: 'center top-10', collision: 'fit fit'},
        tooltipClass: 'center bottom vertical',
        content: -> $($(@).data('tooltipSelector')).html()

    toJSON: ->
      data = @model.toView()
      data.canManage = @canManage()
      data.selector  = @model.get("id") + "_due"
      data.linkHref  = @model.htmlUrl()
      data.allDates  = @model.allDates()
      data

    canManage: ->
      ENV.PERMISSIONS.manage