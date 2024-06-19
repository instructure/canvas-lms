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

import DateValidator from '../DateValidator'
import fakeENV from '@canvas/test-utils/fakeENV'

const DATE_IN_CLOSED_PERIOD = '2015-07-23T03:59:59Z'
const DATE_IN_OPEN_PERIOD = '2015-09-23T03:59:59Z'

function generateData(opts = {}) {
  return {
    id: '32',
    assignment_id: '57',
    title: '1 student',
    due_at: '2015-09-23T03:59:59Z',
    all_day: true,
    all_day_date: '2015-09-22',
    unlock_at: null,
    lock_at: null,
    student_ids: ['2'],
    due_at_overridden: true,
    unlock_at_overridden: true,
    lock_at_overridden: true,
    rowKey: '2015-09-23T03:59:59Z',
    persisted: true,
    ...opts,
  }
}

function generateGradingPeriods(periodOneOpts = {}, periodTwoOpts = {}) {
  const periodOne = {
    id: '1',
    title: 'Closed Period',
    startDate: new Date('2015-07-01T06:00:00.000Z'),
    endDate: new Date('2015-08-31T06:00:00.000Z'),
    closeDate: new Date('2015-08-31T06:00:00.000Z'),
    isLast: false,
    isClosed: true,
    ...periodOneOpts,
  }

  const periodTwo = {
    id: '2',
    title: 'Period',
    startDate: new Date('2015-09-01T06:00:00.000Z'),
    endDate: new Date('2015-10-31T06:00:00.000Z'),
    closeDate: new Date('2015-12-31T06:00:00.000Z'),
    isLast: true,
    isClosed: false,
    ...periodTwoOpts,
  }

  return [periodOne, periodTwo]
}

function createValidator({
  gradingPeriods,
  userIsAdmin,
  hasGradingPeriods = true,
  postToSIS = null,
  dueDateRequiredForAccount = false,
  termStart,
  termEnd,
}) {
  ENV.DUE_DATE_REQUIRED_FOR_ACCOUNT = dueDateRequiredForAccount

  const params = {
    date_range: {
      start_at: {
        date: termStart === undefined ? '2015-03-02T07:00:00Z' : termStart,
        date_context: 'term',
      },
      end_at: {
        date: termEnd === undefined ? '2016-03-31T06:00:00Z' : termEnd,
        date_context: 'term',
      },
    },
    hasGradingPeriods,
    userIsAdmin,
    gradingPeriods,
    postToSIS,
  }

  return new DateValidator(params)
}

function isValid(validator, data) {
  const errors = validator.validateDatetimes(data)
  return Object.keys(errors).length === 0
}

describe('#DateValidator with grading periods', () => {
  test('it is invalid to add a new override with a date in a closed grading period', () => {
    const data = generateData({due_at: DATE_IN_CLOSED_PERIOD, persisted: false})
    const gradingPeriods = generateGradingPeriods()
    const validator = createValidator({gradingPeriods, userIsAdmin: false})
    expect(isValid(validator, data)).toBe(false)
  })

  test('it is invalid for lock_at (until date) to be before due_at on the same day', () => {
    const data = generateData({lock_at: '2015-09-23T03:00:00Z', persisted: false})
    const gradingPeriods = generateGradingPeriods()
    const validator = createValidator({gradingPeriods, userIsAdmin: false})
    expect(isValid(validator, data)).toBe(false)
  })

  test('it is valid for lock_at (until date) to be equal to due_at', () => {
    const data = generateData({lock_at: '2015-09-23T03:59:59Z', persisted: false})
    const gradingPeriods = generateGradingPeriods()
    const validator = createValidator({gradingPeriods, userIsAdmin: false})
    expect(isValid(validator, data)).toBe(true)
  })

  test('it is valid to add a new override with a date in a closed grading period if you are admin', () => {
    const data = generateData({due_at: DATE_IN_CLOSED_PERIOD, persisted: false})
    const gradingPeriods = generateGradingPeriods()
    const validator = createValidator({gradingPeriods, userIsAdmin: true})
    expect(isValid(validator, data)).toBe(true)
  })

  test('it is invalid to add a new override with no date if the last grading period is closed', () => {
    const data = generateData({due_at: null, persisted: false})
    const gradingPeriods = generateGradingPeriods({}, {isClosed: true})
    const validator = createValidator({gradingPeriods, userIsAdmin: false})
    expect(isValid(validator, data)).toBe(false)
  })

  test('it is valid to add a new override with no date if the last grading period is closed if you are admin', () => {
    const data = generateData({due_at: null, persisted: false})
    const gradingPeriods = generateGradingPeriods({}, {isClosed: true})
    const validator = createValidator({gradingPeriods, userIsAdmin: true})
    expect(isValid(validator, data)).toBe(true)
  })

  test('it is valid to have an already-existing (not new) override with a date in a closed grading period', () => {
    const data = generateData({due_at: DATE_IN_CLOSED_PERIOD, persisted: true})
    const gradingPeriods = generateGradingPeriods()
    const validator = createValidator({gradingPeriods, userIsAdmin: false})
    expect(isValid(validator, data)).toBe(true)
  })

  test('it is valid to have an already-existing (not new) override with no date if the last grading period is closed', () => {
    const data = generateData({due_at: null, persisted: true})
    const gradingPeriods = generateGradingPeriods({}, {isClosed: true})
    const validator = createValidator({gradingPeriods, userIsAdmin: false})
    expect(isValid(validator, data)).toBe(true)
  })

  test('it is valid to have a new override with a date that does not fall in a closed grading period', () => {
    const data = generateData({due_at: DATE_IN_OPEN_PERIOD, persisted: false})
    const gradingPeriods = generateGradingPeriods()
    const validator = createValidator({gradingPeriods, userIsAdmin: false})
    expect(isValid(validator, data)).toBe(true)
  })

  test('it is valid to have an already-existing (not new) override with a date that does not fall in a closed grading period', () => {
    const data = generateData({due_at: DATE_IN_OPEN_PERIOD, persisted: true})
    const gradingPeriods = generateGradingPeriods()
    const validator = createValidator({gradingPeriods, userIsAdmin: false})
    expect(isValid(validator, data)).toBe(true)
  })

  test('it is valid to add a new override with no date if the last grading period is open', () => {
    const data = generateData({due_at: null, persisted: false})
    const gradingPeriods = generateGradingPeriods()
    const validator = createValidator({gradingPeriods, userIsAdmin: false})
    expect(isValid(validator, data)).toBe(true)
  })

  test('it is valid to have no due date when postToSISEnabled is false when dueDateRequiredForAccount is true', () => {
    const data = generateData({due_at: null})
    const validator = createValidator({
      gradingPeriods: null,
      userIsAdmin: false,
      hasGradingPeriods: false,
      postToSIS: false,
      dueDateRequiredForAccount: true,
    })
    expect(isValid(validator, data)).toBe(true)
  })

  test('it is not valid to have a missing due date when postToSISEnabled is true when dueDateRequiredForAccount is true', () => {
    const data = generateData({due_at: null})
    const validator = createValidator({
      gradingPeriods: null,
      userIsAdmin: false,
      hasGradingPeriods: false,
      postToSIS: true,
      dueDateRequiredForAccount: true,
    })
    expect(isValid(validator, data)).toBe(false)
  })

  test('it is valid to have a missing due date when postToSISEnabled is true and dueDateRequiredForAccount is false', () => {
    const data = generateData({due_at: null})
    const validator = createValidator({
      gradingPeriods: null,
      userIsAdmin: false,
      hasGradingPeriods: false,
      postToSIS: true,
      dueDateRequiredForAccount: false,
    })
    expect(isValid(validator, data)).toBe(true)
  })
})

describe('when applied to one or more individual students', () => {
  let makeIndividualValidator

  beforeEach(() => {
    makeIndividualValidator = (params = {}) =>
      createValidator({
        dueDateRequiredForAccount: false,
        gradingPeriods: null,
        hasGradingPeriods: false,
        postToSIS: true,
        userIsAdmin: false,
        ...params,
      })
  })

  test('allows a due date before the prescribed start date', () => {
    const data = generateData({
      due_at: '2014-01-23T03:59:59Z',
    })

    const validator = makeIndividualValidator()
    expect(isValid(validator, data)).toBe(true)
  })

  test('accepts all_dates format for student overrides', () => {
    const data = generateData({
      due_at: '2014-01-23T03:59:59Z',
      student_ids: null,
      set_type: 'ADHOC',
      set_id: null,
    })

    const validator = makeIndividualValidator()
    expect(isValid(validator, data)).toBe(true)
  })

  test('allows an unlock date before the prescribed start date', () => {
    const data = generateData({
      unlock_at: '2014-01-23T03:59:59Z',
    })

    const validator = makeIndividualValidator()
    expect(isValid(validator, data)).toBe(true)
  })

  test('allows a due date after the prescribed end date', () => {
    const data = generateData({
      due_at: '2017-01-23T03:59:59Z',
    })
    const validator = makeIndividualValidator()
    expect(isValid(validator, data)).toBe(true)
  })

  test('allows a lock date after the prescribed end date', () => {
    const data = generateData({
      lock_at: '2017-01-23T03:59:59Z',
    })
    const validator = makeIndividualValidator()
    expect(isValid(validator, data)).toBe(true)
  })

  test('does not allow a new override with a date in a closed grading period', () => {
    const data = generateData({
      due_at: DATE_IN_CLOSED_PERIOD,
      persisted: false,
    })

    const gradingPeriods = generateGradingPeriods()
    const validator = makeIndividualValidator({hasGradingPeriods: true, gradingPeriods})
    expect(isValid(validator, data)).toBe(false)
  })
})

describe('term dates', () => {
  let makeIndividualValidator

  beforeEach(() => {
    makeIndividualValidator = (params = {}) =>
      createValidator({
        dueDateRequiredForAccount: false,
        gradingPeriods: null,
        hasGradingPeriods: false,
        postToSIS: true,
        userIsAdmin: false,
        ...params,
      })
  })

  test('allows dates that are in range', () => {
    const data = generateData({
      unlock_at: '2015-03-03T03:59:59Z',
      due_at: '2015-03-04T03:59:59Z',
      lock_at: '2015-03-05T03:59:59Z',
      student_ids: null,
    })
    const validator = makeIndividualValidator()
    expect(isValid(validator, data)).toBe(true)
  })

  test('disallows a due date before the prescribed start date', () => {
    const data = generateData({
      due_at: '2014-01-23T03:59:59Z',
      student_ids: null,
    })

    const validator = makeIndividualValidator()
    expect(isValid(validator, data)).toBe(false)
  })

  test('disallows an unlock date before the prescribed start date', () => {
    const data = generateData({
      unlock_at: '2014-01-23T03:59:59Z',
      student_ids: null,
    })

    const validator = makeIndividualValidator()
    expect(isValid(validator, data)).toBe(false)
  })

  test('disallows a due date after the prescribed end date', () => {
    const data = generateData({
      due_at: '2017-01-23T03:59:59Z',
      student_ids: null,
    })
    const validator = makeIndividualValidator()
    expect(isValid(validator, data)).toBe(false)
  })

  test('disallows a lock date after the prescribed end date', () => {
    const data = generateData({
      lock_at: '2017-01-23T03:59:59Z',
      student_ids: null,
    })
    const validator = makeIndividualValidator()
    expect(isValid(validator, data)).toBe(false)
  })
})

describe('section dates', () => {
  let makeIndividualValidator

  beforeEach(() => {
    makeIndividualValidator = (params = {}) =>
      createValidator({
        dueDateRequiredForAccount: false,
        gradingPeriods: null,
        hasGradingPeriods: false,
        postToSIS: true,
        userIsAdmin: false,
        ...params,
      })
    fakeENV.setup({
      SECTION_LIST: [
        {
          id: 123,
          start_at: '2020-03-01T00:00:00Z',
          end_at: '2020-07-01T00:00:00Z',
          override_course_and_term_dates: true,
        },
        {
          id: 234,
          start_at: null,
          end_at: null,
          override_course_and_term_dates: null,
        },
      ],
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  test('allows dates that are in range', () => {
    const data = generateData({
      unlock_at: '2020-03-03T00:00:00Z',
      due_at: '2020-03-04T00:00:00Z',
      lock_at: '2020-03-05T00:00:00Z',
      student_ids: null,
      course_section_id: 123,
    })
    const validator = makeIndividualValidator()
    expect(isValid(validator, data)).toBe(true)
  })

  test('allows date outside of one section range to be assigned to another, not-limited section', () => {
    const firstSectionDueDateData = generateData({
      unlock_at: '2020-03-03T00:00:00Z',
      due_at: '2020-03-04T00:00:00Z',
      lock_at: '2020-03-05T00:00:00Z',
      student_ids: null,
      course_section_id: 123,
    })

    const secondSectionDueDateData = generateData({
      unlock_at: null,
      due_at: '2020-08-01T00:00:00Z',
      lock_at: null,
      student_ids: null,
      course_section_id: 234,
    })

    const validator = makeIndividualValidator({termStart: null, termEnd: null})
    expect(isValid(validator, firstSectionDueDateData)).toBe(true)
    expect(isValid(validator, secondSectionDueDateData)).toBe(true)
  })

  test('accepts all_dates format for section overrides', () => {
    const data = generateData({
      unlock_at: '2020-03-03T00:00:00Z',
      due_at: '2020-03-04T00:00:00Z',
      lock_at: '2020-03-05T00:00:00Z',
      student_ids: null,
      set_type: 'CourseSection',
      set_id: 123,
    })
    const validator = makeIndividualValidator()
    expect(isValid(validator, data)).toBe(true)
  })

  test('matches the section id', () => {
    const data = generateData({
      unlock_at: '2020-03-03T00:00:00Z',
      due_at: '2020-03-04T00:00:00Z',
      lock_at: '2020-03-05T00:00:00Z',
      student_ids: null,
      course_section_id: 456,
    })
    const validator = makeIndividualValidator()
    expect(isValid(validator, data)).toBe(false)
  })

  test('disallows a due date before the prescribed start date', () => {
    const data = generateData({
      due_at: '2020-01-01T00:00:00Z',
      student_ids: null,
      course_section_id: 123,
    })

    const validator = makeIndividualValidator()
    expect(isValid(validator, data)).toBe(false)
  })

  test('disallows an unlock date before the prescribed start date', () => {
    const data = generateData({
      unlock_at: '2020-01-01T00:00:00Z',
      student_ids: null,
      course_section_id: 123,
    })

    const validator = makeIndividualValidator()
    expect(isValid(validator, data)).toBe(false)
  })

  test('disallows a due date after the prescribed end date', () => {
    const data = generateData({
      due_at: '2020-12-25T00:00:00Z',
      student_ids: null,
      course_section_id: 123,
    })
    const validator = makeIndividualValidator()
    expect(isValid(validator, data)).toBe(false)
  })

  test('disallows a lock date after the prescribed end date', () => {
    const data = generateData({
      lock_at: '2020-12-25T00:00:00Z',
      student_ids: null,
      course_section_id: 123,
    })
    const validator = makeIndividualValidator()
    expect(isValid(validator, data)).toBe(false)
  })
})
