// @ts-nocheck
/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import {find, forEach, isArray, isDate, isString, sortBy} from 'lodash'
import type {CamelizedGradingPeriod} from './grading.d'

function validateDate(date, nullAllowed = false) {
  let valid = isDate(date)
  if (nullAllowed && !valid) {
    valid = date === null
  }

  if (!valid) throw new Error(`\`${date}\` must be a Date or null`)
}

function validateGradingPeriodDates(gradingPeriods) {
  if (gradingPeriods == null) throw new Error(`\'${gradingPeriods}\' must be an array or object`)

  const dates = ['startDate', 'endDate', 'closeDate']
  const periods = isArray(gradingPeriods) ? gradingPeriods : [gradingPeriods]
  forEach(periods, period => {
    forEach(dates, date => validateDate(period[date]))
  })

  return periods
}

function validatePeriodID(id: string) {
  const valid = isString(id)
  if (!valid) throw new Error(`Grading period id \`${id}\` must be a String`)
}

class GradingPeriodsHelper {
  gradingPeriods: CamelizedGradingPeriod[]

  constructor(gradingPeriods) {
    this.gradingPeriods = validateGradingPeriodDates(gradingPeriods)
  }

  static isAllGradingPeriods(periodID: string) {
    validatePeriodID(periodID)

    return periodID === '0'
  }

  get earliestValidDueDate() {
    const orderedPeriods = sortBy(this.gradingPeriods, 'startDate')
    const earliestOpenPeriod = find(orderedPeriods, {isClosed: false})
    if (earliestOpenPeriod) {
      return earliestOpenPeriod.startDate
    } else {
      return null
    }
  }

  gradingPeriodForDueAt(dueAt) {
    validateDate(dueAt, true)

    return (
      find(this.gradingPeriods, period => this.isDateInGradingPeriod(dueAt, period.id, false)) ||
      null
    )
  }

  isDateInGradingPeriod(date, gradingPeriodID, runValidations = true) {
    if (runValidations) {
      validateDate(date, true)
      validatePeriodID(gradingPeriodID)
    }

    const gradingPeriod = find(this.gradingPeriods, {id: gradingPeriodID})
    if (!gradingPeriod) throw new Error(`No grading period has id \`${gradingPeriodID}\``)

    if (date === null) {
      return gradingPeriod.isLast
    } else {
      return gradingPeriod.startDate < date && date <= gradingPeriod.endDate
    }
  }

  isDateInClosedGradingPeriod(date) {
    const period = this.gradingPeriodForDueAt(date)
    return !!period && period.isClosed
  }
}

export default GradingPeriodsHelper
