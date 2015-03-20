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
], ($, _, tz, I18n) ->

  class DateValidator

    constructor: (dateParams) ->
      @dateRange = dateParams['date_range']
      @data = dateParams['data']

    validateDates: ->
      lockAt = @data.lock_at
      unlockAt = @data.unlock_at
      dueAt = @data.due_at
      section = _.find(ENV.SECTION_LIST, {id: @data.course_section_id})

      currentDateRange = if section then @getSectionRange(section) else @dateRange

      datesToValidate = []

      if currentDateRange.start_at?.date
        datesToValidate.push {
          date: currentDateRange.start_at.date,
          validationDates: {"due_at": dueAt, "unlock_at": unlockAt},
          range: "start_range",
          type: currentDateRange.start_at.date_context
        }
      if currentDateRange.end_at?.date
        datesToValidate.push {
          date: currentDateRange.end_at.date,
          validationDates: {"due_at": dueAt, "lock_at": lockAt},
          range: "end_range",
          type: currentDateRange.end_at.date_context
        }
      if dueAt
        datesToValidate.push {
          date: dueAt,
          validationDates: {"lock_at": lockAt},
          range: "start_range",
          type: "due"
        }
        datesToValidate.push {
          date: dueAt,
          validationDates: {"unlock_at": unlockAt},
          range: "end_range",
          type: "due"
        }
      if lockAt
        datesToValidate.push {
          date: lockAt,
          validationDates: {"unlock_at": unlockAt},
          range: "end_range",
          type: "lock"
        }
      errs = {}
      @_validateDateSequences(datesToValidate, errs)

    getSectionRange:(section) ->
      return @dateRange unless section

      if section.start_at
        @dateRange.start_at = {date: section.start_at, date_context: "section" }
      if section.end_at
        @dateRange.end_at = {date: section.end_at, date_context: "section"}

      @dateRange

    _validateDateSequences: (datesToValidate, errs) =>
      for dateSet in datesToValidate
        if dateSet.date
          switch dateSet.range
            when "start_range"
              _.each dateSet.validationDates, (validationDate, dateType) =>
                if validationDate && @_calendarDate(dateSet.date) > @_calendarDate(validationDate)
                  errs[dateType] = DATE_RANGE_ERRORS[dateType][dateSet.range][dateSet.type]
            when "end_range"
              _.each dateSet.validationDates, (validationDate, dateType) =>
                if validationDate && @_calendarDate(dateSet.date) < @_calendarDate(validationDate)
                  errs[dateType] = DATE_RANGE_ERRORS[dateType][dateSet.range][dateSet.type]
      errs

    _calendarDate: (date) ->
      tz.format(tz.parse(date), "%F")

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