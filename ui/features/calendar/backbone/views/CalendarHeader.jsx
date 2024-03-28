/*
 * Copyright (C) 2023 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {extend} from '@canvas/backbone/utils'
import $ from 'jquery'
import Backbone from '@canvas/backbone'
import template from '../../jst/calendarHeader.handlebars'
import CalendarNavigator from './CalendarNavigator'
import {publish, subscribe} from 'jquery-tinypubsub'

import React from 'react'
import ReactDOM from 'react-dom'
import CalendarHeaderComponent from '../../react/CalendarHeaderComponent'

extend(CalendarHeader, Backbone.View)

function CalendarHeader() {
  this.animateLoading = this.animateLoading.bind(this)
  this.setHeaderText = this.setHeaderText.bind(this)
  return CalendarHeader.__super__.constructor.apply(this, arguments)
}

CalendarHeader.prototype.template = template

if (!ENV.FEATURES?.instui_header) {
  CalendarHeader.prototype.els = {
    '.calendar_view_buttons': '$calendarViewButtons',
    '.recommend_agenda': '$recommendAgenda',
    '.calendar_navigator': '$navigator',
    '#create_new_event_link': '$createNewEventLink',
    '#refresh_calendar_link': '$refreshCalendarLink',
  }
}

CalendarHeader.prototype.events = {
  'click #week': '_triggerWeek',
  'click #month': '_triggerMonth',
  'click #agenda': '_triggerAgenda',
  'click #use_agenda': '_selectAgenda',
  'click #create_new_event_link': '_triggerCreateNewEvent',
  'click #refresh_calendar_link': '_triggerRefreshCalendar',
  'keydown .calendar_view_buttons': '_handleKeyDownEvent',
  'focus .recommend_agenda': '_showVisualAgendaRecommendation',
  'blur .recommend_agenda': '_hideVisualAgendaRecommendation',
}

CalendarHeader.prototype.initialize = function () {
  CalendarHeader.__super__.initialize.apply(this, arguments)
  return this.render()
}

CalendarHeader.prototype.connectEvents = function () {
  const _this = this
  this.navigator.on('navigatePrev', function () {
    _this.trigger('navigatePrev')
  })
  this.navigator.on('navigateToday', function () {
    _this.trigger('navigateToday')
  })
  this.navigator.on('navigateNext', function () {
    _this.trigger('navigateNext')
  })
  this.navigator.on('navigateDate', function (selectedDate) {
    _this.trigger('navigateDate', selectedDate)
  })
  this.$calendarViewButtons.on('click', 'button', this.toggleView.bind(this))
  return subscribe('Calendar/loadStatus', this.animateLoading.bind(this))
}

CalendarHeader.prototype.toggleView = function (e) {
  e.preventDefault()
  const $target = $(e.currentTarget)
  $target.attr('aria-selected', true).addClass('active').attr('tabindex', 0)
  return $target.siblings().attr('aria-selected', false).removeClass('active').attr('tabindex', -1)
}

CalendarHeader.prototype.moveToCalendarViewButton = function (direction) {
  const buttons = this.$calendarViewButtons.children('button')
  const active = this.$calendarViewButtons.find('.active')
  let activeIndex = buttons.index(active)
  const lastIndex = buttons.length - 1
  if (direction === 'prev') {
    activeIndex = (activeIndex + lastIndex) % buttons.length
  } else if (direction === 'next') {
    activeIndex = (activeIndex + 1) % buttons.length
  }
  return buttons.eq(activeIndex).focus().click()
}

CalendarHeader.prototype.showNavigator = function () {
  this.$navigator.show()
  return this.$createNewEventLink.show()
}

CalendarHeader.prototype._showVisualAgendaRecommendation = function () {
  return this.$recommendAgenda.removeClass('screenreader-only')
}

CalendarHeader.prototype._hideVisualAgendaRecommendation = function () {
  return this.$recommendAgenda.addClass('screenreader-only')
}

CalendarHeader.prototype.showAgendaRecommendation = function () {
  return this.$recommendAgenda.show()
}

CalendarHeader.prototype.hideAgendaRecommendation = function () {
  return this.$recommendAgenda.hide()
}

CalendarHeader.prototype.setHeaderText = function (newText) {
  return this.navigator.setTitle(newText)
}

CalendarHeader.prototype.selectView = function (viewName) {
  return $('#' + viewName).click()
}

CalendarHeader.prototype.animateLoading = function (shouldAnimate) {
  return this.$refreshCalendarLink.toggleClass('loading', shouldAnimate)
}

CalendarHeader.prototype.setSchedulerBadgeCount = function (badgeCount) {
  return this.$badge.toggle(badgeCount > 0).text(badgeCount)
}

CalendarHeader.prototype.showPrevNext = function () {
  return this.navigator.showPrevNext()
}

CalendarHeader.prototype.hidePrevNext = function () {
  return this.navigator.hidePrevNext()
}

CalendarHeader.prototype._selectAgenda = function (_event) {
  return this.selectView('agenda')
}

CalendarHeader.prototype._triggerWeek = function (_event) {
  if (ENV.FEATURES?.instui_header) {
    document.dispatchEvent(new CustomEvent('calendar:header:select_view', {detail: {viewName: 'week'}}))
  }

  return this.trigger('week')
}

CalendarHeader.prototype._triggerMonth = function (_event) {
  if (ENV.FEATURES?.instui_header) {
    document.dispatchEvent(new CustomEvent('calendar:header:select_view', {detail: {viewName: 'month'}}))
  }

  return this.trigger('month')
}

CalendarHeader.prototype._triggerAgenda = function (_event) {
  if (ENV.FEATURES?.instui_header) {
    document.dispatchEvent(new CustomEvent('calendar:header:select_view', {detail: {viewName: 'agenda'}}))
  }
  
  return this.trigger('agenda')
}

CalendarHeader.prototype._triggerCreateNewEvent = function (event) {
  event.preventDefault()
  this.trigger('createNewEvent')
  return publish('CalendarHeader/createNewEvent')
}

CalendarHeader.prototype._triggerRefreshCalendar = function (event) {
  event.preventDefault()
  return this.trigger('refreshCalendar')
}

CalendarHeader.prototype._handleKeyDownEvent = function (event) {
  switch (event.which) {
    case 37:
    case 38:
      event.preventDefault()
      return this.moveToCalendarViewButton('prev')
    case 39:
    case 40:
      event.preventDefault()
      return this.moveToCalendarViewButton('next')
  }
}

CalendarHeader.prototype._loadObjects = function(options = null) {
  this.navigator = new CalendarNavigator({
    el: this.$navigator,
    size: options?.size,
  })
  this.showNavigator()
  // The badge is part of the buttonset, so we can't find it beforehand with els
  this.$badge = this.$el.find('.counter-badge')
  this.setSchedulerBadgeCount(0)
  this.connectEvents()
}

CalendarHeader.prototype.afterRender = function() {
  if (!ENV.FEATURES?.instui_header) {
    return this._loadObjects()
  }

  ReactDOM.render(
    <CalendarHeaderComponent 
      bridge={{
        onLoadReady: (options) => {
          if (this.navigator) return

          this.$calendarViewButtons = this.$el.find('.calendar_view_buttons')
          this.$recommendAgenda = this.$el.find('.recommend_agenda')
          this.$navigator = this.$el.find('.calendar_navigator')
          this.$createNewEventLink = this.$el.find('#create_new_event_link')
          this.$refreshCalendarLink = this.$el.find('#refresh_calendar_link')

          this._loadObjects(options)
        },
        onChangeSelectViewMode: (viewName) => this.selectView(viewName),
      }} />, 
    this.$el.find('#calendar_header_component')[0]
  )
}

export default CalendarHeader
