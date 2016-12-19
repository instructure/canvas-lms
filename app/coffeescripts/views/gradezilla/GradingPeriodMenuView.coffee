define [
  'compiled/userSettings'
  'i18n!gradezilla'
  'jquery'
  'underscore'
  'Backbone'
  'jst/gradezilla/grading_period_to_show_menu'
   'compiled/jquery.kylemenu'
  'vendor/jquery.ba-tinypubsub'
], (userSettings, I18n, $, _, {View}, template) ->

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
      @storePeriodSetting period
      @render()

    storePeriodSetting: (period) ->
      userSettings.contextSet('gradebook_current_grading_period', period)

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
