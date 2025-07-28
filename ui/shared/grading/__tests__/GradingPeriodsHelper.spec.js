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

import GradingPeriodsHelper from '../GradingPeriodsHelper'

const DATE_IN_FIRST_PERIOD = new Date('July 15, 2015')
const DATE_IN_LAST_PERIOD = new Date('Sep 15, 2015')
const DATE_OUTSIDE_OF_ANY_PERIOD = new Date('Jun 15, 2015')

function generateGradingPeriods() {
  return [
    {
      id: '101',
      startDate: new Date('2015-07-01T06:00:00Z'),
      endDate: new Date('2015-08-31T06:00:00Z'),
      title: 'Closed Period',
      closeDate: new Date('2015-08-31T06:00:00Z'),
      isLast: false,
      isClosed: true,
    },
    {
      id: '102',
      startDate: new Date('2015-09-01T06:00:00Z'),
      endDate: new Date('2015-10-31T06:00:00Z'),
      title: 'Period',
      closeDate: new Date('2015-11-15T06:00:00Z'),
      isLast: true,
      isClosed: false,
    },
  ]
}

describe('GradingPeriodsHelper', () => {
  describe('constructor', () => {
    test('throws an error if any dates on the grading periods are Strings', () => {
      const gradingPeriods = generateGradingPeriods()
      gradingPeriods[0].startDate = '2015-07-01T06:00:00Z'
      expect(() => {
        new GradingPeriodsHelper(gradingPeriods)
      }).toThrow()
    })

    test('throws an error if any dates on the grading periods are null', () => {
      const gradingPeriods = generateGradingPeriods()
      gradingPeriods[0].startDate = null
      expect(() => {
        new GradingPeriodsHelper(gradingPeriods)
      }).toThrow()
    })

    test('throws an error if grading periods are not passed in', () => {
      expect(() => {
        new GradingPeriodsHelper()
      }).toThrow()
    })
  })

  describe('isAllGradingPeriods', () => {
    test('returns true if the ID is the string "0"', () => {
      expect(GradingPeriodsHelper.isAllGradingPeriods('0')).toBe(true)
    })

    test('returns false if the ID is a string other than "0"', () => {
      expect(GradingPeriodsHelper.isAllGradingPeriods('42')).toBe(false)
    })

    test('throws an error if the ID is not a string', () => {
      expect(() => {
        GradingPeriodsHelper.isAllGradingPeriods(0)
      }).toThrow()
    })
  })

  describe('gradingPeriodForDueAt', () => {
    let helper

    beforeEach(() => {
      const gradingPeriods = generateGradingPeriods()
      helper = new GradingPeriodsHelper(gradingPeriods)
    })

    test('returns the grading period that the given due at falls in', () => {
      const period = helper.gradingPeriodForDueAt(DATE_IN_FIRST_PERIOD)
      expect(period).toBe(helper.gradingPeriods[0])
    })

    test('returns the last grading period if the due at is null', () => {
      const period = helper.gradingPeriodForDueAt(null)
      expect(period).toBe(helper.gradingPeriods[1])
    })

    test('returns null if the given due at does not fall in any grading period', () => {
      const period = helper.gradingPeriodForDueAt(DATE_OUTSIDE_OF_ANY_PERIOD)
      expect(period).toBeNull()
    })

    test('throws an error if the due at is a String', () => {
      expect(() => {
        helper.gradingPeriodForDueAt('Jan 20, 2015')
      }).toThrow()
    })
  })

  describe('isDateInGradingPeriod', () => {
    let helper, firstPeriod, lastPeriod

    beforeEach(() => {
      const gradingPeriods = generateGradingPeriods()
      helper = new GradingPeriodsHelper(gradingPeriods)
      firstPeriod = gradingPeriods[0]
      lastPeriod = gradingPeriods[1]
    })

    test('returns true if the given date falls in the grading period', () => {
      expect(helper.isDateInGradingPeriod(DATE_IN_FIRST_PERIOD, firstPeriod.id)).toBe(true)
    })

    // passes in QUnit, fails in Jest
    test.skip('returns true if the given date exactly matches the grading period start date', () => {
      const exactStartDate = firstPeriod.startDate
      expect(helper.isDateInGradingPeriod(exactStartDate, firstPeriod.id)).toBe(true)
    })

    // passes in QUnit, fails in Jest
    test.skip('returns false if the given date exactly matches the grading period end date', () => {
      const exactEndDate = firstPeriod.endDate
      expect(helper.isDateInGradingPeriod(exactEndDate, firstPeriod.id)).toBe(false)
    })

    test('returns false if the given date falls outside the grading period', () => {
      expect(helper.isDateInGradingPeriod(DATE_OUTSIDE_OF_ANY_PERIOD, firstPeriod.id)).toBe(false)
    })

    test('returns true if the given date is null and the grading period is the last period', () => {
      expect(helper.isDateInGradingPeriod(null, lastPeriod.id)).toBe(true)
    })

    test('returns false if the given date is null and the grading period is not the last period', () => {
      expect(helper.isDateInGradingPeriod(null, firstPeriod.id)).toBe(false)
    })

    test('throws an error if the given date is a String', () => {
      expect(() => {
        helper.isDateInGradingPeriod('Jan 20, 2015', firstPeriod.id)
      }).toThrow()
    })

    test('throws an error if no grading period exists with the given id', () => {
      expect(() => {
        helper.isDateInGradingPeriod(DATE_IN_FIRST_PERIOD, '222')
      }).toThrow()
    })
  })

  describe('earliestValidDueDate', () => {
    let gradingPeriods, helper, firstPeriod, secondPeriod

    beforeEach(() => {
      gradingPeriods = generateGradingPeriods()
      firstPeriod = gradingPeriods[0]
      secondPeriod = gradingPeriods[1]
    })

    test('returns the start date of the earliest open grading period', () => {
      let earliestDate = new GradingPeriodsHelper(gradingPeriods).earliestValidDueDate
      expect(earliestDate).toBe(secondPeriod.startDate)

      firstPeriod.isClosed = false
      earliestDate = new GradingPeriodsHelper(gradingPeriods).earliestValidDueDate
      expect(earliestDate).toBe(firstPeriod.startDate)
    })

    test('returns null if there are no open grading periods', () => {
      secondPeriod.isClosed = true
      const earliestDate = new GradingPeriodsHelper(gradingPeriods).earliestValidDueDate
      expect(earliestDate).toBeNull()
    })
  })

  describe('isDateInClosedGradingPeriod', () => {
    let helper

    beforeEach(() => {
      const gradingPeriods = generateGradingPeriods()
      helper = new GradingPeriodsHelper(gradingPeriods)
    })

    test('returns true if a date falls in a closed grading period', () => {
      expect(helper.isDateInClosedGradingPeriod(DATE_IN_FIRST_PERIOD)).toBe(true)
    })
    test('returns false if a date falls in an open grading period', () => {
      expect(helper.isDateInClosedGradingPeriod(DATE_IN_LAST_PERIOD)).toBe(false)
    })

    test('returns false if a date does not fall in any grading period', () => {
      expect(helper.isDateInClosedGradingPeriod(DATE_OUTSIDE_OF_ANY_PERIOD)).toBe(false)
    })
  })
})
