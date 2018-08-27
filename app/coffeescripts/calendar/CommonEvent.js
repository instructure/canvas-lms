/*
 * Copyright (C) 2012 - present Instructure, Inc.
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
import 'jquery.ajaxJSON'
import 'vendor/jquery.ba-tinypubsub'
import splitAssetString from 'compiled/str/splitAssetString'

export default function CommonEvent(data, contextInfo, actualContextInfo) {
  this.eventType = 'generic'
  this.contextInfo = contextInfo
  this.actualContextInfo = actualContextInfo
  this.allPossibleContexts = null
  this.className = []
  this.object = {}

  this.copyDataFromObject(data)
}

Object.assign(CommonEvent.prototype, {
  readableTypes: {
    assignment: I18n.t('Assignment'),
    discussion: I18n.t('Discussion'),
    event: I18n.t('Event'),
    quiz: I18n.t('Quiz'),
    note: I18n.t('To Do'),
    wiki_page: I18n.t('Page'),
    discussion_topic: I18n.t('Discussion')
  },

  isNewEvent() {
    return this.eventType === 'generic' || !(this.object && this.object.id)
  },

  isAppointmentGroupFilledEvent() {
    return (
      this.object &&
      this.object.child_events &&
      this.object.child_events.length > 0
    )
  },

  isAppointmentGroupEvent() {
    return this.object && this.object.appointment_group_url
  },

  contextCode() {
    return (
      (this.object && this.object.effective_context_code) ||
      (this.object && this.object.context_code) ||
      (this.contextInfo && this.contextInfo.asset_string)
    )
  },

  contextApiPrefix() {
    const context = splitAssetString(this.contextCode())
    return `/api/v1/${encodeURIComponent(context[0])}/${encodeURIComponent(context[1])}`
  },

  isUndated() {
    return this.start == null
  },

  isCompleted() {
    return false
  },

  displayTimeString() {
    return ''
  },
  readableType() {
    return ''
  },

  fullDetailsURL() {
    return null
  },

  startDate() {
    return this.originalStart || this.date
  },
  endDate() {
    return this.startDate()
  },

  possibleContexts() {
    return this.allPossibleContexts || [this.contextInfo]
  },

  addClass(newClass) {
    this.className.push(newClass)
  },

  removeClass(rmClass) {
    this.className = this.className.filter(c => c !== rmClass)
  },

  save(params, success, error) {
    const onSuccess = data => {
      this.copyDataFromObject(data)
      $.publish('CommonEvent/eventSaved', this)
      if (typeof success === 'function') return success()
    }

    const onError = data => {
      this.copyDataFromObject(data)
      $.publish('CommonEvent/eventSaveFailed', this)
      if (typeof error === 'function') return error()
    }

    const [method, url] = this.methodAndURLForSave()

    this.forceMinimumDuration() // so short events don't look squished while waiting for ajax
    $.publish('CommonEvent/eventSaving', this)
    return $.ajaxJSON(url, method, params, onSuccess, onError)
  },

  isDueAtMidnight() {
    return (
      this.start &&
      (this.midnightFudged ||
        (this.start.hours() === 23 && this.start.minutes() > 30) ||
        (this.start.hours() === 0 && this.start.minutes() === 0))
    )
  },

  isPast() {
    return this.start && this.start < fcUtil.now()
  },

  copyDataFromObject(data) {
    this.originalStart = this.start && fcUtil.clone(this.start)
    this.midnightFudged = false // clear out cached value because now we have new data
    if (this.isDueAtMidnight()) {
      this.midnightFudged = true
      this.start.minutes(30)
      this.start.seconds(0)
      if (!this.end) {
        this.end = fcUtil.clone(this.start)
      }
    } else {
      // minimum duration should only be enforced if not due at midnight
      this.forceMinimumDuration()
    }
    return this.preventWrappingAcrossDates()
  },

  formatTime(datetime, allDay = false) {
    let formattedHtml
    if (!datetime) {
      return null
    }
    datetime = fcUtil.unwrap(datetime)
    if (allDay) {
      formattedHtml = $.dateString(datetime)
    } else {
      formattedHtml = $.datetimeString(datetime)
    }
    return `<time datetime='${datetime.toISOString()}'>${formattedHtml}</time>`
  },

  forceMinimumDuration() {
    if (this.start && this.end) {
      const minimumEnd = fcUtil.clone(this.start).add(30, 'minutes')
      if (minimumEnd > this.end) {
        return (this.end = minimumEnd)
      }
    }
  },

  preventWrappingAcrossDates() {
    if (
      this.start &&
      this.start.hours() === 23 &&
      this.start.minutes() > 0 &&
      (!this.end || this.start.isSame(this.end))
    ) {
      return (this.end = fcUtil.clone(this.start).add(60 - this.start.minutes(), 'minutes'))
    }
  },

  assignmentType() {
    if (!this.assignment) return
    if (
      this.assignment.submission_types &&
      this.assignment.submission_types.length
    ) {
      const type = this.assignment.submission_types[0]
      if (type === 'online_quiz') return 'quiz'
      if (type === 'discussion_topic') return 'discussion'
    }
    return 'assignment'
  },

  plannerObjectType() {
    switch(this.object.plannable_type) {
      case 'discussion_topic':
        return 'discussion'
      case 'wiki_page':
        return 'document'
      default:
        return null
    }
  },

  iconType() {
    let type
    if ((type = this.assignmentType())) {
      return type
    } else if ((type = this.plannerObjectType())) {
      return type
    } else if (this.eventType === 'planner_note') {
      return 'note-light'
    } else if (ENV.CALENDAR.BETTER_SCHEDULER) {
      if (
        this.isAppointmentGroupEvent() &&
        (this.isAppointmentGroupFilledEvent() || this.appointmentGroupEventStatus === 'Reserved')
      ) {
        return 'calendar-reserved'
      } else if (this.isAppointmentGroupEvent()) {
        return 'calendar-add'
      } else {
        return 'calendar-month'
      }
    } else {
      return 'calendar-month'
    }
  },

  isOnCalendar(context_code) {
    return this.calendarEvent.all_context_codes.match(new RegExp(`\\b${context_code}\\b`))
  }
})
