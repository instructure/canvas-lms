#
# Copyright (C) 2012 - present Instructure, Inc.
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
  'i18n!calendar'
  'jquery'
  'compiled/util/fcUtil'
  'jquery.ajaxJSON'
  'vendor/jquery.ba-tinypubsub'
], (I18n, $, fcUtil) ->

  class
    readableTypes:
      assignment: I18n.t('event_type.assignment', 'Assignment')
      discussion: I18n.t('event_type.discussion', 'Discussion')
      event: I18n.t('event_type.event', 'Event')
      quiz: I18n.t('event_type.quiz', 'Quiz')

    constructor: (data, contextInfo, actualContextInfo) ->
      @eventType = 'generic'
      @contextInfo = contextInfo
      @actualContextInfo = actualContextInfo
      @allPossibleContexts = null
      @className = []
      @object = {}

      @copyDataFromObject(data)

    isNewEvent: () ->
      @eventType == 'generic' || !@object?.id

    isAppointmentGroupFilledEvent: () ->
      @object?.child_events?.length > 0

    isAppointmentGroupEvent: () ->
      @object?.appointment_group_url

    contextCode: () ->
      @object?.effective_context_code || @object?.context_code || @contextInfo?.asset_string

    isUndated: () ->
      @start == null

    isCompleted: -> false

    displayTimeString: () -> ""
    readableType: () -> ""

    fullDetailsURL: () -> null

    startDate: () -> @originalStart || @date
    endDate: () -> @startDate()

    possibleContexts: () -> @allPossibleContexts || [ @contextInfo ]

    addClass: (newClass) ->
      found = false
      for c in @className
        if c == newClass
          found = true
          break
      if !found then @className.push newClass

    removeClass: (rmClass) ->
      idx = 0
      for c in @className
        if c == rmClass
          @className.splice(idx, 1)
        else
          idx += 1

    save: (params, success, error) ->
      onSuccess = (data) =>
        @copyDataFromObject(data)
        $.publish "CommonEvent/eventSaved", this
        success?()

      onError = (data) =>
        @copyDataFromObject(data)
        $.publish "CommonEvent/eventSaveFailed", this
        error?()

      [ method, url ] = @methodAndURLForSave()

      @forceMinimumDuration() # so short events don't look squished while waiting for ajax
      $.publish "CommonEvent/eventSaving", this
      $.ajaxJSON url, method, params, onSuccess, onError

    isDueAtMidnight: () ->
      @start && (@midnightFudged || (@start.hours() == 23 && @start.minutes() > 30) || (@start.hours() == 0 && @start.minutes() == 0))

    isPast: () ->
      @start && @start < fcUtil.now()

    copyDataFromObject: (data) ->
      @originalStart = (fcUtil.clone(@start) if @start)
      @midnightFudged = false # clear out cached value because now we have new data
      if @isDueAtMidnight()
        @midnightFudged = true
        @start.minutes(30)
        @start.seconds(0)
        @end = fcUtil.clone(@start) unless @end
      else
        # minimum duration should only be enforced if not due at midnight
        @forceMinimumDuration()
      @preventWrappingAcrossDates()

    formatTime: (datetime, allDay=false) ->
      return null unless datetime
      datetime = fcUtil.unwrap(datetime)
      if allDay
        formattedHtml = $.dateString(datetime)
      else
        formattedHtml = $.datetimeString(datetime)
      "<time datetime='#{datetime.toISOString()}'>#{formattedHtml}</time>"

    forceMinimumDuration: () ->
      if @start && @end
        minimumEnd = fcUtil.clone(@start).add(30, "minutes")
        @end = minimumEnd if minimumEnd > @end

    preventWrappingAcrossDates: () ->
      if @start && @start.hours() == 23 && @start.minutes() > 0 && (!@end || @start.isSame(@end))
        @end = fcUtil.clone(@start).add(60 - @start.minutes(), "minutes")

    assignmentType: () ->
      return if !@assignment
      if @assignment.submission_types?.length
        type = @assignment.submission_types[0]
        if type == 'online_quiz'
          return 'quiz'
        if type == 'discussion_topic'
          return 'discussion'
      return 'assignment'

    iconType: ->
      if type = @assignmentType()
        type
      else if ENV.CALENDAR.BETTER_SCHEDULER
        if @isAppointmentGroupEvent() && (@isAppointmentGroupFilledEvent() || @appointmentGroupEventStatus == "Reserved")
          'calendar-reserved'
        else if @isAppointmentGroupEvent()
          'calendar-add'
        else
          'calendar-month'
      else
        'calendar-month'

    isOnCalendar: (context_code) ->
      @calendarEvent.all_context_codes.match(///\b#{context_code}\b///)
