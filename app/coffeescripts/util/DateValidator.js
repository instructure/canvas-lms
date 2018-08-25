//
// Copyright (C) 2015 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.
//

import _ from 'underscore'
import tz from 'timezone'
import I18n from 'i18n!overrides'
import GradingPeriodsHelper from 'jsx/grading/helpers/GradingPeriodsHelper'
import DateHelper from 'jsx/shared/helpers/dateHelper'

const DATE_RANGE_ERRORS = {
  due_at: {
    start_range: {
      section: I18n.t('Due date cannot be before section start'),
      course: I18n.t('Due date cannot be before course start'),
      term: I18n.t('Due date cannot be before term start'),
    },
    end_range: {
      section: I18n.t('Due date cannot be after section end'),
      course: I18n.t('Due date cannot be after course end'),
      term: I18n.t('Due date cannot be after term end'),
    },
  },
  unlock_at: {
    start_range: {
      section: I18n.t('Unlock date cannot be before section start'),
      course: I18n.t('Unlock date cannot be before course start'),
      term: I18n.t('Unlock date cannot be before term start'),
    },
    end_range: {
      due: I18n.t('Unlock date cannot be after due date'),
      lock: I18n.t('Unlock date cannot be after lock date'),
    },
  },
  lock_at: {
    start_range: {
      due: I18n.t('Lock date cannot be before due date'),
    },
    end_range: {
      section: I18n.t('Lock date cannot be after section end'),
      course: I18n.t('Lock date cannot be after course end'),
      term: I18n.t('Lock date cannot be after term end'),
    },
  },
}

export default class DateValidator {

  constructor (params) {
    this.dateRange = params.date_range
    this.data = params.data
    this.forIndividualStudents = params.forIndividualStudents
    this.hasGradingPeriods = params.hasGradingPeriods
    this.gradingPeriods = params.gradingPeriods
    this.userIsAdmin = params.userIsAdmin
    this.dueDateRequired = params.postToSIS && ENV.DUE_DATE_REQUIRED_FOR_ACCOUNT
  }

  validateDatetimes () {
    const lockAt = this.data.lock_at
    const unlockAt = this.data.unlock_at
    const dueAt = this.data.due_at
    const section = _.find(ENV.SECTION_LIST, {id: this.data.course_section_id})
    const currentDateRange = section ? this.getSectionRange(section) : this.dateRange
    const datetimesToValidate = []

    if (currentDateRange.start_at && currentDateRange.start_at.date && !this.forIndividualStudents) {
      datetimesToValidate.push({
        date: currentDateRange.start_at.date,
        validationDates: {
          due_at: dueAt,
          unlock_at: unlockAt,
        },
        range: 'start_range',
        type: currentDateRange.start_at.date_context,
      })
    }
    if (currentDateRange.end_at && currentDateRange.end_at.date && !this.forIndividualStudents) {
      datetimesToValidate.push({
        date: currentDateRange.end_at.date,
        validationDates: {
          due_at: dueAt,
          lock_at: lockAt,
        },
        range: 'end_range',
        type: currentDateRange.end_at.date_context,
      })
    }
    if (dueAt) {
      datetimesToValidate.push({
        date: dueAt,
        validationDates: {
          lock_at: lockAt,
        },
        range: 'start_range',
        type: 'due',
      })
      datetimesToValidate.push({
        date: dueAt,
        validationDates: {
          unlock_at: unlockAt,
        },
        range: 'end_range',
        type: 'due',
      })
    }

    if (this.dueDateRequired) {
      datetimesToValidate.push({
        date: dueAt,
        dueDateRequired: this.dueDateRequired,
      })
    }

    if (this.hasGradingPeriods && !this.userIsAdmin && this.data.persisted === false) {
      datetimesToValidate.push({
        date: dueAt,
        range: 'grading_period_range',
      })
    }

    if (lockAt) {
      datetimesToValidate.push({
        date: lockAt,
        validationDates: {
          unlock_at: unlockAt,
        },
        range: 'end_range',
        type: 'lock',
      })
    }
    const errs = {}
    return this._validateDatetimeSequences(datetimesToValidate, errs)
  }

  getSectionRange (section) {
    if (!section.override_course_and_term_dates) return this.dateRange

    if (section.start_at) {
      this.dateRange.start_at = {
        date: section.start_at,
        date_context: 'section',
      }
    }
    if (section.end_at) {
      this.dateRange.end_at = {
        date: section.end_at,
        date_context: 'section',
      }
    }

    return this.dateRange
  }

  _validateMultipleGradingPeriods (date, errs) {
    const helper = new GradingPeriodsHelper(this.gradingPeriods)
    const dueAt = date === null ? null : new Date(this._formatDatetime(date))
    if (!helper.isDateInClosedGradingPeriod(dueAt)) return

    const earliestDate = helper.earliestValidDueDate
    if (earliestDate) {
      const formatted = DateHelper.formatDateForDisplay(earliestDate)
      errs.due_at = I18n.t('Please enter a due date on or after %{earliestDate}', {
        earliestDate: formatted,
      })
    } else {
      errs.due_at = I18n.t('Due date cannot fall in a closed grading period')
    }
  }

  _validateDatetimeSequences (datetimesToValidate, errs) {
    datetimesToValidate.forEach((datetimeSet) => {
      if (datetimeSet.dueDateRequired && !datetimeSet.date) {
        errs.due_at = I18n.t('Please add a due date')
      }
      if (datetimeSet.range === 'grading_period_range') {
        this._validateMultipleGradingPeriods(datetimeSet.date, errs)
      } else if (datetimeSet.date) {
        switch (datetimeSet.range) {
          case 'start_range':
            _.each(datetimeSet.validationDates, (validationDate, dateType) => {
              if (validationDate && this._formatDatetime(datetimeSet.date) > this._formatDatetime(validationDate)) {
                errs[dateType] = DATE_RANGE_ERRORS[dateType][datetimeSet.range][datetimeSet.type]
              }
            })
            break
          case 'end_range':
            _.each(datetimeSet.validationDates, (validationDate, dateType) => {
              if (validationDate && this._formatDatetime(datetimeSet.date) < this._formatDatetime(validationDate)) {
                errs[dateType] = DATE_RANGE_ERRORS[dateType][datetimeSet.range][datetimeSet.type]
              }
            })
            break
        }
      }
    })
    return errs
  }

  _formatDatetime (date) {
    return tz.format(tz.parse(date), '%F %R')
  }
}
