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

  deleteConfirmation = I18n.t('prompts.delete_assignment', "Are you sure you want to delete this assignment?")

  class Assignment extends CommonEvent
    constructor: (data, contextInfo) ->
      super
      @eventType = 'assignment'
      @deleteConfirmation = deleteConfirmation
      @deleteURL = contextInfo.assignment_url
      @addClass 'assignment'

    copyDataFromObject: (data) ->
      data = data.assignment if data.assignment
      @object = @assignment = data
      @id = "assignment_#{data.id}" if data.id
      @title = data.title || data.name  || "Untitled" # due to a discrepancy between the legacy ajax API and the v1 API
      @lock_explanation = @object.lock_explanation
      @addClass "group_#{@contextCode()}"
      @description = data.description
      @start = @parseStartDate()
      @end = null # in case it got set by midnight fudging

      super

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

    saveDates: (success, error) ->
      @save { 'assignment[due_at]': if @start then fcUtil.unwrap(@start).toISOString() else '' }, success, error

    save: (params, success, error) ->
      $.publish('CommonEvent/assignmentSaved', @)
      super(params, success, error)

    methodAndURLForSave: () ->
      if @isNewEvent()
        method = 'POST'
        url = @contextInfo.create_assignment_url
      else
        method = 'PUT'
        url = $.replaceTags(@contextInfo.assignment_url, 'id', @assignment.id)
      [ method, url ]

    isCompleted: ->
      @assignment.user_submitted || (this.isPast() && @assignment.needs_grading_count == 0)
