/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import I18n from 'i18n!calendar'
import $ from 'jquery'
import fcUtil from '../util/fcUtil'
import semanticDateRange from '../util/semanticDateRange'
import CommonEvent from '../calendar/CommonEvent'
import natcompare from '../util/natcompare'
import {extend} from '../legacyCoffeesScriptHelpers'
import 'jquery.instructure_date_and_time'
import 'jquery.instructure_misc_helpers'

extend(CalendarEvent, CommonEvent)
export default function CalendarEvent(data, contextInfo, actualContextInfo) {
  CalendarEvent.__super__.constructor.call(this, data, contextInfo, actualContextInfo)
  this.eventType = 'calendar_event'
  this.appointmentGroupEventStatus = this.calculateAppointmentGroupEventStatus()
  this.reservedUsers = this.getListOfReservedPeople(5).join('; ')
  this.deleteConfirmation = I18n.t('Are you sure you want to delete this event?')
  this.deleteURL = contextInfo.calendar_event_url
}

Object.assign(CalendarEvent.prototype, {
  copyDataFromObject(data) {
    if (data.calendar_event) {
      data = data.calendar_event
    }
    this.object = this.calendarEvent = data
    if (data.id) this.id = `calendar_event_${data.id}`
    this.title = data.title || 'Untitled'
    this.comments = data.comments
    this.location_name = data.location_name
    this.location_address = data.location_address
    this.start = this.parseStartDate()
    this.end = this.parseEndDate()
    // see originalStart in super's copyDataFromObject
    if (this.end) this.originalEndDate = fcUtil.clone(this.end)
    this.allDay = data.all_day
    this.editable = true
    this.lockedTitle = this.object.parent_event_id != null
    this.description = data.description
    this.addClass(`group_${this.contextCode()}`)
    if (this.isAppointmentGroupEvent()) {
      this.addClass('scheduler-event')
      if (this.object.reserved) {
        this.addClass('scheduler-reserved')
      }
      if (this.object.available_slots === 0) {
        this.addClass('scheduler-full')
      }
      if (this.object.available_slots === undefined || this.object.available_slots > 0) {
        this.addClass('scheduler-available')
      }
      this.editable = false
    }
    return CalendarEvent.__super__.copyDataFromObject.apply(this, arguments)
  },

  endDate() {
    return this.originalEndDate
  },

  parseStartDate() {
    if (this.calendarEvent.start_at) {
      return fcUtil.wrap(this.calendarEvent.start_at)
    }
  },

  parseEndDate() {
    if (this.calendarEvent.end_at) {
      return fcUtil.wrap(this.calendarEvent.end_at)
    }
  },

  fullDetailsURL() {
    if (this.isAppointmentGroupEvent()) {
      return `/appointment_groups/${this.object.appointment_group_id}`
    } else {
      return $.replaceTags(
        this.contextInfo.calendar_event_url,
        'id',
        this.calendarEvent.parent_event_id || this.calendarEvent.id
      )
    }
  },

  editGroupURL() {
    if (this.isAppointmentGroupEvent()) {
      return `/appointment_groups/${this.object.appointment_group_id}/edit`
    } else {
      return '#'
    }
  },

  displayTimeString() {
    if (this.calendarEvent.all_day && this.calendarEvent.start_at === this.calendarEvent.end_at) {
      return this.formatTime(this.startDate(), true)
    } else {
      return semanticDateRange(this.calendarEvent.start_at, this.calendarEvent.end_at)
    }
  },

  readableType() {
    return this.readableTypes.event
  },

  saveDates(success, error) {
    return this.save(
      {
        'calendar_event[start_at]': this.start ? fcUtil.unwrap(this.start).toISOString() : '',
        'calendar_event[end_at]': this.end ? fcUtil.unwrap(this.end).toISOString() : '',
        'calendar_event[all_day]': this.allDay
      },
      success,
      error
    )
  },

  methodAndURLForSave() {
    let method, url
    if (this.isNewEvent()) {
      method = 'POST'
      url = '/api/v1/calendar_events'
    } else {
      method = 'PUT'
      url = this.calendarEvent.url
    }
    return [method, url]
  },

  calculateAppointmentGroupEventStatus() {
    let status = I18n.t('Available')
    if (this.calendarEvent.available_slots > 0) {
      status = I18n.t('%{availableSlots} Available', {availableSlots: I18n.n(this.calendarEvent.available_slots)})
    }
    if (this.calendarEvent.available_slots > 0 && (this.calendarEvent.child_events && this.calendarEvent.child_events.length)) {
      status = I18n.t('%{availableSlots} more available', {availableSlots: I18n.n(this.calendarEvent.available_slots)})
    }
    if (this.calendarEvent.available_slots === 0) {
      status = I18n.t('Filled')
    }
    if (this.consideredReserved()) {
      status = I18n.t('Reserved')
    }

    return status
  },

  // Returns an array of sortable user names that have reserved this slot optionally
  // limited to a certain number.  The list is returned sorted naturally.  If there
  // are more than the limit 'and more...' will be appended.

  getListOfReservedPeople(limit) {
    if (
      !(
        this.calendarEvent &&
        this.calendarEvent.child_events &&
        this.calendarEvent.child_events.length
      )
    ) {
      return []
    }

    const names = ((this.calendarEvent && this.calendarEvent.child_events) || []).map(
      child_event => child_event.user && child_event.user.sortable_name
    )
    let sorted = names.sort((a, b) => natcompare.strings(a, b))

    if (limit) {
      sorted = sorted.slice(0, limit)
      if (
        (this.calendarEvent &&
          this.calendarEvent.child_events &&
          this.calendarEvent.child_events.length) > limit
      ) {
        sorted.push(I18n.t('and more...'))
      }
    }
    return sorted
  },

  // True if the slot should be considered reserved
  consideredReserved() {
    return (
      this.calendarEvent.reserved === true ||
      (this.calendarEvent.appointment_group_url && this.calendarEvent.parent_event_id)
    )
  }
})
