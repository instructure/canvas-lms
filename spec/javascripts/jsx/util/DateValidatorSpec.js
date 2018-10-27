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

import DateValidator from 'compiled/util/DateValidator'

const DATE_IN_CLOSED_PERIOD = '2015-07-23T03:59:59Z'
const DATE_IN_OPEN_PERIOD = '2015-09-23T03:59:59Z'

function generateData(opts = {}) {
  return Object.assign(
    {
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
      persisted: true
    },
    opts
  )
}

function generateGradingPeriods(periodOneOpts = {}, periodTwoOpts = {}) {
  const periodOne = Object.assign(
    {
      id: '1',
      title: 'Closed Period',
      startDate: new Date('2015-07-01T06:00:00.000Z'),
      endDate: new Date('2015-08-31T06:00:00.000Z'),
      closeDate: new Date('2015-08-31T06:00:00.000Z'),
      isLast: false,
      isClosed: true
    },
    periodOneOpts
  )

  const periodTwo = Object.assign(
    {
      id: '2',
      title: 'Period',
      startDate: new Date('2015-09-01T06:00:00.000Z'),
      endDate: new Date('2015-10-31T06:00:00.000Z'),
      closeDate: new Date('2015-12-31T06:00:00.000Z'),
      isLast: true,
      isClosed: false
    },
    periodTwoOpts
  )

  return [periodOne, periodTwo]
}

function createValidator({
  data,
  gradingPeriods,
  userIsAdmin,
  forIndividualStudents = false,
  hasGradingPeriods = true,
  postToSIS = null,
  dueDateRequiredForAccount = false
}) {
  ENV.DUE_DATE_REQUIRED_FOR_ACCOUNT = dueDateRequiredForAccount

  const params = {
    date_range: {
      start_at: {
        date: '2015-03-02T07:00:00Z',
        date_context: 'term'
      },
      end_at: {
        date: '2016-03-31T06:00:00Z',
        date_context: 'term'
      }
    },
    hasGradingPeriods: true,
    forIndividualStudents,
    userIsAdmin,
    data,
    gradingPeriods,
    postToSIS
  }

  return new DateValidator(params)
}

function isValid(validator) {
  const errors = validator.validateDatetimes()
  return Object.keys(errors).length === 0
}

QUnit.module('#DateValidator with grading periods')

test('it is invalid to add a new override with a date in a closed grading period', function() {
  const data = generateData({due_at: DATE_IN_CLOSED_PERIOD, persisted: false})
  const gradingPeriods = generateGradingPeriods()
  const validator = createValidator({data, gradingPeriods, userIsAdmin: false})
  notOk(isValid(validator))
})

test('it is invalid for lock_at (until date) to be before due_at on the same day', function() {
  const data = generateData({lock_at: '2015-09-23T03:00:00Z', persisted: false})
  const gradingPeriods = generateGradingPeriods()
  const validator = createValidator({data, gradingPeriods, userIsAdmin: false})
  notOk(isValid(validator))
})

test('it is valid for lock_at (until date) to be equal to due_at', function() {
  const data = generateData({lock_at: '2015-09-23T03:59:59Z', persisted: false})
  const gradingPeriods = generateGradingPeriods()
  const validator = createValidator({data, gradingPeriods, userIsAdmin: false})
  ok(isValid(validator))
})

test('it is valid to add a new override with a date in a closed grading period if you are admin', function() {
  const data = generateData({due_at: DATE_IN_CLOSED_PERIOD, persisted: false})
  const gradingPeriods = generateGradingPeriods()
  const validator = createValidator({data, gradingPeriods, userIsAdmin: true})
  ok(isValid(validator))
})

test('it is invalid to add a new override with no date if the last grading period is closed', function() {
  const data = generateData({due_at: null, persisted: false})
  const gradingPeriods = generateGradingPeriods({}, {isClosed: true})
  const validator = createValidator({data, gradingPeriods, userIsAdmin: false})
  notOk(isValid(validator))
})

test('it is valid to add a new override with no date if the last grading period is closed if you are admin', function() {
  const data = generateData({due_at: null, persisted: false})
  const gradingPeriods = generateGradingPeriods({}, {isClosed: true})
  const validator = createValidator({data, gradingPeriods, userIsAdmin: true})
  ok(isValid(validator))
})

test('it is valid to have an already-existing (not new) override with a date in a closed grading period', function() {
  const data = generateData({due_at: DATE_IN_CLOSED_PERIOD, persisted: true})
  const gradingPeriods = generateGradingPeriods()
  const validator = createValidator({data, gradingPeriods, userIsAdmin: false})
  ok(isValid(validator))
})

test('it is valid to have an already-existing (not new) override with no date if the last grading period is closed', function() {
  const data = generateData({due_at: null, persisted: true})
  const gradingPeriods = generateGradingPeriods({}, {isClosed: true})
  const validator = createValidator({data, gradingPeriods, userIsAdmin: false})
  ok(isValid(validator))
})

test('it is valid to have a new override with a date that does not fall in a closed grading period', function() {
  const data = generateData({due_at: DATE_IN_OPEN_PERIOD, persisted: false})
  const gradingPeriods = generateGradingPeriods()
  const validator = createValidator({data, gradingPeriods, userIsAdmin: false})
  ok(isValid(validator))
})

test('it is valid to have an already-existing (not new) override with a date that does not fall in a closed grading period', function() {
  const data = generateData({due_at: DATE_IN_OPEN_PERIOD, persisted: true})
  const gradingPeriods = generateGradingPeriods()
  const validator = createValidator({data, gradingPeriods, userIsAdmin: false})
  ok(isValid(validator))
})

test('it is valid to add a new override with no date if the last grading period is open', function() {
  const data = generateData({due_at: null, persisted: false})
  const gradingPeriods = generateGradingPeriods()
  const validator = createValidator({data, gradingPeriods, userIsAdmin: false})
  ok(isValid(validator))
})

test('it is valid to have no due date when postToSISEnabled is false when dueDateRequiredForAccount is true', function() {
  const data = generateData({due_at: null})
  const validator = createValidator({
    data,
    gradingPeriods: null,
    userIsAdmin: false,
    hasGradingPeriods: false,
    postToSIS: false,
    dueDateRequiredForAccount: true
  })
  ok(isValid(validator))
})

test('it is not valid to have a missing due date when postToSISEnabled is true when dueDateRequiredForAccount is true', function() {
  const data = generateData({due_at: null})
  const validator = createValidator({
    data,
    gradingPeriods: null,
    userIsAdmin: false,
    hasGradingPeriods: false,
    postToSIS: true,
    dueDateRequiredForAccount: true
  })
  notOk(isValid(validator))
})

test('it is valid to have a missing due date when postToSISEnabled is true and dueDateRequiredForAccount is false', function() {
  const data = generateData({due_at: null})
  const validator = createValidator({
    data,
    gradingPeriods: null,
    userIsAdmin: false,
    hasGradingPeriods: false,
    postToSIS: true,
    dueDateRequiredForAccount: false
  })
  ok(isValid(validator))
})

QUnit.module('when applied to one or more individual students', hooks => {
  let makeIndividualValidator

  hooks.beforeEach(() => {
    makeIndividualValidator = (data, params = {}) =>
      createValidator({
        data,
        dueDateRequiredForAccount: false,
        forIndividualStudents: true,
        gradingPeriods: null,
        hasGradingPeriods: false,
        postToSIS: true,
        userIsAdmin: false,
        ...params
      })
  })

  test('allows a due date before the prescribed start date', () => {
    const data = generateData({
      due_at: '2014-01-23T03:59:59Z'
    })

    const validator = makeIndividualValidator(data)
    ok(isValid(validator))
  })

  test('allows an unlock date before the prescribed start date', () => {
    const data = generateData({
      unlock_at: '2014-01-23T03:59:59Z'
    })

    const validator = makeIndividualValidator(data)
    ok(isValid(validator))
  })

  test('allows a due date after the prescribed end date', () => {
    const data = generateData({
      due_at: '2017-01-23T03:59:59Z'
    })
    const validator = makeIndividualValidator(data)
    ok(isValid(validator))
  })

  test('allows a lock date after the prescribed end date', () => {
    const data = generateData({
      lock_at: '2017-01-23T03:59:59Z'
    })
    const validator = makeIndividualValidator(data)
    ok(isValid(validator))
  })

  test('does not allow a new override with a date in a closed grading period', function() {
    const data = generateData({
      due_at: DATE_IN_CLOSED_PERIOD,
      persisted: false
    })

    const gradingPeriods = generateGradingPeriods()
    const validator = makeIndividualValidator(data, {hasGradingPeriods: true, gradingPeriods})
    notOk(isValid(validator))
  })
})
