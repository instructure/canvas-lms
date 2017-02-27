#
# Copyright (C) 2013 Instructure, Inc.
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
#

define [
  'jquery'
  'underscore'
  'timezone'
  'i18n!overrides'
  'jsx/grading/helpers/GradingPeriodsHelper'
  'jsx/shared/helpers/dateHelper'
], ($, _, tz, I18n, GradingPeriodsHelper, DateHelper) ->

  class DateValidator

    constructor: (params) ->
      @dateRange = params['date_range']
      @data = params['data']
      @hasGradingPeriods = params.hasGradingPeriods
      @gradingPeriods = params.gradingPeriods
      @userIsAdmin = params.userIsAdmin
      @dueDateRequired = params.postToSIS && ENV.DUE_DATE_REQUIRED_FOR_ACCOUNT

    validateDatetimes: ->
      lockAt = @data.lock_at
      unlockAt = @data.unlock_at
      dueAt = @data.due_at
      section = _.find(ENV.SECTION_LIST, {id: @data.course_section_id})

      currentDateRange = if section then @getSectionRange(section) else @dateRange

      datetimesToValidate = []

      if currentDateRange.start_at?.date
        datetimesToValidate.push {
          date: currentDateRange.start_at.date,
          validationDates: {"due_at": dueAt, "unlock_at": unlockAt},
          range: "start_range",
          type: currentDateRange.start_at.date_context
        }
      if currentDateRange.end_at?.date
        datetimesToValidate.push {
          date: currentDateRange.end_at.date,
          validationDates: {"due_at": dueAt, "lock_at": lockAt},
          range: "end_range",
          type: currentDateRange.end_at.date_context
        }
      if dueAt
        datetimesToValidate.push {
          date: dueAt,
          validationDates: {"lock_at": lockAt},
          range: "start_range",
          type: "due"
        }
        datetimesToValidate.push {
          date: dueAt,
          validationDates: {"unlock_at": unlockAt},
          range: "end_range",
          type: "due"
        }

      if @dueDateRequired
        datetimesToValidate.push {
          date: dueAt,
          dueDateRequired: @dueDateRequired,
        }

      if @hasGradingPeriods && !@userIsAdmin && @data.persisted == false
        datetimesToValidate.push {
          date: dueAt,
          range: "grading_period_range",
        }

      if lockAt
        datetimesToValidate.push {
          date: lockAt,
          validationDates: {"unlock_at": unlockAt},
          range: "end_range",
          type: "lock"
        }
      errs = {}
      @_validateDatetimeSequences(datetimesToValidate, errs)

    getSectionRange:(section) ->
      return @dateRange unless section.override_course_and_term_dates

      if section.start_at
        @dateRange.start_at = {date: section.start_at, date_context: "section" }
      if section.end_at
        @dateRange.end_at = {date: section.end_at, date_context: "section"}

      @dateRange

    _validateMultipleGradingPeriods: (date, errs) =>
      helper = new GradingPeriodsHelper(@gradingPeriods)
      dueAt = if date == null then null else new Date(@_formatDatetime(date))
      return unless helper.isDateInClosedGradingPeriod(dueAt)

      earliestDate = helper.earliestValidDueDate
      if earliestDate
        formatted = DateHelper.formatDateForDisplay(earliestDate)
        errs["due_at"] = I18n.t("Please enter a due date on or after %{earliestDate}", earliestDate: formatted)
      else
        errs["due_at"] = I18n.t("Due date cannot fall in a closed grading period")

    _validateDatetimeSequences: (datetimesToValidate, errs) =>
      for datetimeSet in datetimesToValidate
        if datetimeSet.dueDateRequired && !datetimeSet.date
          errs["due_at"] = I18n.t("Please add a due date")
        if datetimeSet.range == "grading_period_range"
          @_validateMultipleGradingPeriods(datetimeSet.date, errs)
        else if datetimeSet.date
          switch datetimeSet.range
            when "start_range"
              _.each datetimeSet.validationDates, (validationDate, dateType) =>
                if validationDate && @_formatDatetime(datetimeSet.date) > @_formatDatetime(validationDate)
                  errs[dateType] = DATE_RANGE_ERRORS[dateType][datetimeSet.range][datetimeSet.type]
            when "end_range"
              _.each datetimeSet.validationDates, (validationDate, dateType) =>
                if validationDate && @_formatDatetime(datetimeSet.date) < @_formatDatetime(validationDate)
                  errs[dateType] = DATE_RANGE_ERRORS[dateType][datetimeSet.range][datetimeSet.type]
      errs

    _formatDatetime: (date) ->
      tz.format(tz.parse(date), "%F %R")

    DATE_RANGE_ERRORS = {
      "due_at": {
        "start_range": {
          "section": I18n.t('Due date cannot be before section start')
          "course": I18n.t('Due date cannot be before course start')
          "term": I18n.t('Due date cannot be before term start')
        },
        "end_range": {
          "section": I18n.t('Due date cannot be after section end')
          "course": I18n.t('Due date cannot be after course end')
          "term": I18n.t('Due date cannot be after term end')
        }
      },
      "unlock_at": {
        "start_range": {
          "section": I18n.t('Unlock date cannot be before section start')
          "course": I18n.t('Unlock date cannot be before course start')
          "term": I18n.t('Unlock date cannot be before term start')
        },
        "end_range" : {
          "due": I18n.t('Unlock date cannot be after due date'),
          "lock": I18n.t('Unlock date cannot be after lock date')
        }
      },
      "lock_at": {
        "start_range": {
          "due": I18n.t('Lock date cannot be before due date')
        },
        "end_range": {
          "section": I18n.t('Lock date cannot be after section end')
          "course": I18n.t('Lock date cannot be after course end')
          "term": I18n.t('Lock date cannot be after term end')
        }
      }
    }
