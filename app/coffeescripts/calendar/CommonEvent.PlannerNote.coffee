#
# Copyright (C) 2017 - present Instructure, Inc.
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
  plannerNotesAPI = '/api/v1/planner_notes'

  class PlannerNote extends CommonEvent
    constructor: (data, contextInfo, actualContextInfo) ->
      super data, contextInfo, actualContextInfo
      @eventType = 'planner_note'
      @deleteConfirmation = deleteConfirmation
      @deleteURL = encodeURI("#{plannerNotesAPI}/{{ id }}")

    # beware: copyDateFromObj is called before our constructor
    # because it's call from super's constructor comes here
    # copyDataFromObject makes the incoming planner_note look like a calendar event
    # if we get here via a request for the list of notes (see EventDataSource), some of the
    # fields are already filled in, but if we get here because we just edited a planner_note
    # they are not.
    copyDataFromObject: (data) ->
      data.type = "planner_note"
      data.description = data.details
      data.planner_note_id = data.id
      data.start_at = data.todo_date
      data.end_at = null
      data.all_day = true
      data.url = "#{location.origin}#{plannerNotesAPI}/#{data.planner_note_id}"
      data.context_code = if data.course_id then "course_#{data.course_id}" else "user_#{data.user_id}"
      data.all_context_codes = data.context_code



      data = data.calendar_event if data.calendar_event
      @object = @calendarEvent = data
      @id = "planner_note_#{data.id}" if data.id
      @title = data.title || "Untitled"
      @start = @parseStartDate()
      @end = undefined
      @allDay = data.all_day
      # see originalStart in super's copyDataFromObject
      @originalEndDate = fcUtil.clone(@end) if @end
      @editable = true
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
    saveDates: (success, error) ->
      @save {
        title: @title
        details: @description
        todo_date: fcUtil.unwrap(@start).toISOString()
        id: @object.id
        type: 'planner_note'
      }, success, error

    methodAndURLForSave: () ->
      if @isNewEvent()
        method = 'POST'
        url = plannerNotesAPI
      else
        method = 'PUT'
        url = "#{plannerNotesAPI}/#{this.object.id}"
      [ method, url ]
