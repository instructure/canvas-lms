#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  '../../userSettings'
  'i18n!gradebook'
  'jquery'
  'underscore'
  'Backbone'
  'jst/gradebook/grading_period_to_show_menu'
   '../../jquery.kylemenu'
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
