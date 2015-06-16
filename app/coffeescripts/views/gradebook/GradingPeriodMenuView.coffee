define [
  'i18n!gradebook2'
  'jquery'
  'underscore'
  'Backbone'
  'jst/gradebook2/grading_period_to_show_menu'
   'compiled/jquery.kylemenu'
  'vendor/jquery.ba-tinypubsub'
], (I18n, $, _, {View}, template) ->

  class GradingPeriodMenuView extends View

    @optionProperty 'periods'

    @optionProperty 'currentGradingPeriod'

    template: template

    defaultPeriod: I18n.t('All Grading Periods')

    constructor: (options) ->
      super
      @periods.unshift(title: @defaultPeriod, id:0, checked: !options.currentGradingPeriod)

    render: ->
      @detachEvents()
      super
      @$('button').kyleMenu()
      @attachEvents()

    detachEvents: ->
      $.unsubscribe('currentGradingPeriod/change', @onGradingPeriodChange)
      @$('.grading-period-select-menu').off('menuselect')

    attachEvents: ->
      $.subscribe('currentGradingPeriod/change', @onGradingPeriodChange)
      @$('.grading-period-select-menu').on('click', (e) -> e.preventDefault())
      @$('.grading-period-select-menu').on('menuselect', (event, ui) =>
        period = @$('[aria-checked=true] input[name=period_to_show_radio]').val() || undefined
        $.publish('currentGradingPeriod/change', [period, @cid])
        @trigger('menuselect', event, ui, @currentGradingPeriod)
      )

    onGradingPeriodChange: (period) =>
      @currentGradingPeriod = period
      @updateGradingPeriods()
      @render()

    updateGradingPeriods: ->
      _.map(@periods, (period) =>
        period.checked = period.id == @currentGradingPeriod
        period
      )

    toJSON: ->
      {
        periods: @periods,
        currentGradingPeriod: _.findWhere(@periods, id: @currentGradingPeriod)?.title or @defaultPeriod
      }
