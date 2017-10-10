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
  'compiled/util/semanticDateRange'
  'compiled/calendar/CommonEvent'
  'compiled/util/natcompare'
  'jquery.instructure_date_and_time'
  'jquery.instructure_misc_helpers'
], (I18n, $, fcUtil, semanticDateRange, CommonEvent, natcompare) ->

  deleteConfirmation = I18n.t("Are you sure you want to delete this To Do item?")

  class PlannerNote extends CommonEvent
    constructor: (data, contextInfo, actualContextInfo) ->
      super data, contextInfo, actualContextInfo
      @eventType = 'planner_note'
      @deleteConfirmation = deleteConfirmation
      @plannerNotesAPI = '/api/v1/planner_notes'
      @deleteURL = encodeURI("#{{@plannerNotesAPI}}/{{ id }}")

    # beware: copyDateFromObj is called before our constructor
    # because it's call from super's constructor comes here
    copyDataFromObject: (data) ->
      data = data.calendar_event if data.calendar_event
      @object = @calendarEvent = data
      @id = "planner_note_#{data.id}" if data.id
      @title = data.title || "Untitled"
      @start = @parseStartDate()
      @end = undefined
      @allDay = data.all_day
      # see originalStart in super's copyDataFromObject
      @originalEndDate = fcUtil.clone(@end) if @end
      @editable = false
      @lockedTitle = @object.parent_event_id?
      @description = data.description
      @addClass "group_#{@contextCode()}"

      super

    endDate: () -> @originalEndDate

    parseStartDate: () ->
      fcUtil.wrap(@calendarEvent.start_at) if @calendarEvent.start_at

    displayTimeString: () ->
      @formatTime(@startDate(), true)

    readableType: () ->
      @readableTypes[@event_type]

    # called at the end of a drag and drop operation
    # TODO: change when we can edit in the calendar
    saveDates: (success, error) ->
      @save {
        # 'calendar_event[start_at]': if @start then fcUtil.unwrap(@start).toISOString() else ''
        # 'calendar_event[end_at]': if @end then fcUtil.unwrap(@end).toISOString() else ''
        # 'calendar_event[all_day]': @allDay
      }, success, error

    methodAndURLForSave: () ->
      if @isNewEvent()
        method = 'POST'
        url = '/api/v1/planner_note'
      else
        method = 'PUT'
        url = @calendarEvent.url
      [ method, url ]
