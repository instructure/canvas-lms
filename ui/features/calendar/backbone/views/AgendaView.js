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

/* eslint-disable no-void */

import {extend} from '@canvas/backbone/utils'
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import * as tz from '@canvas/datetime'
import fcUtil from '@canvas/calendar/jquery/fcUtil'
import calendarEventFilter from '../../CalendarEventFilter'
import {map, minBy, includes, first, filter, reduce, isEmpty, last, sortBy} from 'lodash'
import Backbone from '@canvas/backbone'
import ShowEventDetailsDialog from '../../jquery/ShowEventDetailsDialog'
import template from '../../jst/agendaView.handlebars'
import '../../fcMomentHandlebarsHelpers' // make sure fcMomentToString is available to agendaView.handlebars
import 'jquery-tinypubsub'
import userSettings from '@canvas/user-settings'

const I18n = useI18nScope('calendar')

extend(AgendaView, Backbone.View)

AgendaView.prototype.PER_PAGE = 50

AgendaView.prototype.template = template

AgendaView.prototype.els = {
  '.agenda-actions .loading-spinner': '$spinner',
}

AgendaView.prototype.events = {
  'click .agenda-load-btn': 'loadMore',
  'click .agenda-event__item-container': 'manageEvent',
  'keyclick .agenda-event__item-container': 'manageEvent',
}

AgendaView.prototype.messages = {
  loading_more_items: I18n.t('loading_more_items', 'Loading more items.'),
}

AgendaView.optionProperty('calendar')

// Can't be tied to the AgendaView object, because it must maintain persistance.

let currentIndex = -1

let focusedAlready = false

function AgendaView() {
  this.eventBoxToHash = this.eventBoxToHash.bind(this)
  this.formattedLongDayString = this.formattedLongDayString.bind(this)
  this.formattedDayString = this.formattedDayString.bind(this)
  this.render = this.render.bind(this)
  this.loadMoreFinished = this.loadMoreFinished.bind(this)
  this.appendEvents = this.appendEvents.bind(this)
  this.handleEvents = this.handleEvents.bind(this)
  this.refetch = this.refetch.bind(this)
  AgendaView.__super__.constructor.apply(this, arguments)
  this.dataSource = this.options.dataSource
  this.contextObjects = this.options.contextObjects
  this.viewingGroup = null
  $.subscribe({
    'CommonEvent/eventDeleted': this.refetch,
    'CommonEvent/eventSaved': this.refetch,
    'CalendarHeader/createNewEvent': this.handleNewEvent,
  })
}

AgendaView.prototype.hide = function () {
  return this.$el.removeClass('active')
}

AgendaView.prototype.fetch = function (contexts, start) {
  this.$el.empty()
  this.$el.addClass('active')
  this.contexts = contexts
  this.startDate = fcUtil.clone(start).stripTime()
  return this._fetch(this.startDate, this.handleEvents)
}

AgendaView.prototype._fetch = function (start, callback) {
  const end = fcUtil.clone(start).year(3000)
  this.lastRequestID = $.guid++
  return this.dataSource.getEvents(start, end, this.contexts, callback, void 0, {
    singlePage: true,
    per_page: 100,
    requestID: this.lastRequestID,
  })
}

AgendaView.prototype.refetch = function () {
  if (!this.startDate) {
    return
  }
  this.collection = []
  return this._fetch(this.startDate, this.handleEvents)
}

AgendaView.prototype.handleEvents = function (events) {
  if (events.requestID !== this.lastRequestID) {
    return
  }
  this.collection = []
  return this.appendEvents(events)
}

AgendaView.prototype.appendEvents = function (events) {
  let ref
  this.nextPageDate = events.nextPageDate
  // eslint-disable-next-line prefer-spread
  this.collection.push.apply(
    this.collection,
    calendarEventFilter(
      this.viewingGroup,
      events,
      (ref = this.calendar) != null ? ref.schedulerState : void 0
    )
  )
  this.collection = sortBy(this.collection, 'originalStart')
  return this.render()
}

AgendaView.prototype.loadMore = function (e) {
  e.preventDefault()
  this.$spinner.show()
  this._fetch(this.nextPageDate, this.loadMoreFinished)
  return $.screenReaderFlashMessage(this.messages.loading_more_items)
}

AgendaView.prototype.loadMoreFinished = function (events) {
  this.appendEvents(events)
  return this.focusFirstNewDate(events)
}

AgendaView.prototype.focusFirstNewDate = function (events) {
  const firstNewEvent = minBy(events, function (e) {
    return e.start
  })
  const $firstEvent = this.$("li[data-event-id='" + firstNewEvent.id + "']")
  const $firstEventDay = $firstEvent.closest('.agenda-day')
  const $firstEventDayDate = $firstEventDay.find('.agenda-date')
  if ($firstEventDayDate.length) {
    return $firstEventDayDate[0].focus()
  }
}

AgendaView.prototype.refocusAfterRender = function () {
  let children, elementToFocus
  if ((!this.collection.length || currentIndex === -1) && focusedAlready) {
    $('#create_new_event_link').focus()
    return (currentIndex = -1)
  } else if (currentIndex >= 0) {
    children = this.$('.agenda-event__list').children()
    elementToFocus = $(children[currentIndex] || children[children.length - 1])
      .children()
      .first()
    if (elementToFocus) {
      return elementToFocus.focus()
    }
  }
}

AgendaView.prototype.manageEvent = function (e) {
  let allowedContexts
  e.preventDefault()
  e.stopPropagation()
  focusedAlready = true
  const eventEl = $(e.target).closest('.agenda-event__item')
  const eventId = eventEl.data('event-id')
  currentIndex = -1
  this.collection.forEach(
    (function (_this) {
      return function (val, index, _list) {
        if (val.id === eventId) {
          return (currentIndex = index)
        }
      }
    })(this)
  )
  const event = this.dataSource.eventWithId(eventId)
  if (event.can_change_context) {
    allowedContexts =
      userSettings.get('checked_calendar_codes') || map(this.contextObjects, 'asset_string')
    event.allPossibleContexts = filter(this.contextObjects, function (c) {
      return includes(allowedContexts, c.asset_string)
    })
  }
  return new ShowEventDetailsDialog(event, this.dataSource).show(e)
}

AgendaView.prototype.handleNewEvent = function (_e) {
  return (currentIndex = -1)
}

AgendaView.prototype.render = function () {
  AgendaView.__super__.render.apply(this, arguments)
  this.$spinner.hide()
  $.publish('Calendar/colorizeContexts')
  this.refocusAfterRender()
  const lastEvent = last(this.collection)
  if (!lastEvent) {
    return
  }
  return this.trigger('agendaDateRange', this.startDate, lastEvent.originalStart)
}

// Internal: Change a flat array of objects into a sturctured array of
// objects based on the given iterator function. Similar to _.groupBy,
// except the result is an Array instead of a Hash and this function
// assumes the list is already sorted by the given iterator.
//
// list     - The sorted list of values to box.
// iterator - A function that returns the value to box by. The iterator
//             is passed the value from the list.
//
// Returns a new boxed array with elemens from the given list.
AgendaView.prototype.sortedBoxBy = function (list, iterator) {
  return reduce(
    list,
    function (result, currentElt) {
      if (isEmpty(result)) {
        return [[currentElt]]
      }
      const previousBox = last(result)
      const previousElt = last(previousBox)
      if (iterator(currentElt) === iterator(previousElt)) {
        previousBox.push(currentElt)
      } else {
        result.push([currentElt])
      }
      return result
    },
    []
  )
}

// Internal: returns the 'start' of the event formatted for the template
//   event - the event to format
// Returns the formatted String
AgendaView.prototype.formattedDayString = function (event) {
  return tz.format(fcUtil.unwrap(event.originalStart), 'date.formats.short_with_weekday')
}

// Internal: returns the 'start' of the event formatted for the template
// Shown to screen reader users, so they hear real month and day names, and
//   not letters like "D E C" or "W E D", or words like "dec" (read "deck")
//   event - the event to format
// Returns the formatted String
AgendaView.prototype.formattedLongDayString = function (event) {
  return tz.format(fcUtil.unwrap(event.originalStart), 'date.formats.long_with_weekday')
}

// Internal: change a box of events into an output hash for toJSON
//   events - a box of events (all the events occur on the same day)
// Returns an Object with 'date' and 'events' keys.
AgendaView.prototype.eventBoxToHash = function (events) {
  const now = fcUtil.now()
  const event = first(events)
  const start = event.originalStart
  const isToday =
    now.date() === start.date() && now.month() === start.month() && now.year() === start.year()
  return {
    date: this.formattedDayString(event),
    accessibleDate: this.formattedLongDayString(event),
    isToday,
    events,
  }
}

// Internal: Format a hash of event data to an object ready to be sent to the template.
//   boxedEvents - A boxed list of events
// Returns an object in the format specified by toJSON.
AgendaView.prototype.formatResult = function (boxedEvents) {
  return {
    days: map(boxedEvents, this.eventBoxToHash),
    meta: {
      hasMore: !!this.nextPageDate,
      displayAppointmentEvents: this.viewingGroup,
      use_scheduler: ENV.CALENDAR.SHOW_SCHEDULER,
    },
  }
}

// Public: Creates the json for the template.
//
// Returns an Object:
//   {
//     days: [
//       [date: 'some date', events: [event1.toJSON(), event2.toJSON()],
//       [date: ...]
//     ],
//     meta: {
//       hasMore: true/false
//     }
//   }
AgendaView.prototype.toJSON = function () {
  const list = this.sortedBoxBy(this.collection, this.formattedDayString)
  return this.formatResult(list)
}

export default AgendaView
