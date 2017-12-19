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
  '../calendar/CommonEvent'
  '../util/fcUtil'
  'jquery.instructure_date_and_time'
  'jquery.instructure_misc_helpers'
], (I18n, $, CommonEvent, fcUtil) ->

  deleteConfirmation = I18n.t('prompts.delete_override', 'Are you sure you want to delete this assignment override?')

  class AssignmentOverride extends CommonEvent
    constructor: (data, contextInfo) ->
      super
      @eventType          = 'assignment_override'
      @deleteConfirmation = deleteConfirmation
      @deleteUrl          = contextInfo.assignment_url
      @addClass 'assignment_override'

    copyDataFromObject: (data) ->
      if data.assignment?
        @copyDataFromAssignment(data.assignment)
        @copyDataFromOverride(data.assignment_override)
      else
        @copyDataFromOverride(data)

      @title  = "#{@assignment.name} (#{@override.title})"
      @object = @override
      @addClass("group_#{@contextCode()}")
      super

    copyDataFromAssignment: (assignment) ->
      @assignment = assignment
      @lock_explanation = @assignment.lock_explanation
      @description = @assignment.description
      @start = @parseStartDate()
      @end = null # in case it got set by midnight fudging

    copyDataFromOverride: (override) ->
      @override = override
      @id = "override_#{@override.id}"
      @assignment.due_at = @override.due_at

    fullDetailsURL: () ->
      @assignment.html_url

    parseStartDate: () ->
      fcUtil.wrap(@assignment.due_at) if @assignment.due_at

    displayTimeString: () ->
      datetime = @originalStart
      if datetime
        I18n.t('Due: %{dueAt}', dueAt: @formatTime(datetime))
      else
        I18n.t('No Date')

    readableType: () ->
      @readableTypes[@assignmentType()]

    updateAssignmentTitle: (title) ->
      @assignment.title = title
      titleContext = @title.match(/\(.+\)$/)[0]
      @title = "#{title} #{titleContext}"

    saveDates: (success, error) ->
      @save { 'assignment_override[due_at]': if @start then fcUtil.unwrap(@start).toISOString() else ''}, success, error

    methodAndURLForSave: () ->
      url = $.replaceTags(@contextInfo.assignment_override_url,
        assignment_id: @assignment.id,
        id: @override.id)
      ['PUT', url]

    isCompleted: ->
      @assignment.user_submitted || (this.isPast() && @assignment.needs_grading_count == 0)
