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

import _ from 'lodash'
import * as timezone from '@canvas/datetime'
import {scopeToUser, updateWithSubmissions} from '@canvas/grading/EffectiveDueDates'

QUnit.module('EffectiveDueDates', () => {
  QUnit.module('.scopeToUser', () => {
    const exampleDueDatesData = {
      201: {
        101: {
          due_at: '2015-05-04T12:00:00Z',
          grading_period_id: '701',
          in_closed_grading_period: true,
        },
        102: {
          due_at: '2015-05-05T12:00:00Z',
          grading_period_id: '701',
          in_closed_grading_period: true,
        },
      },
      202: {
        101: {
          due_at: '2015-06-04T12:00:00Z',
          grading_period_id: '702',
          in_closed_grading_period: false,
        },
      },
    }

    test('returns a map with effective due dates keyed to assignment ids', () => {
      const scopedDueDates = scopeToUser(exampleDueDatesData, '101')
      deepEqual(_.keys(scopedDueDates).sort(), ['201', '202'])
      deepEqual(_.keys(scopedDueDates[201]).sort(), [
        'due_at',
        'grading_period_id',
        'in_closed_grading_period',
      ])
    })

    test('includes all effective due dates for the given user', () => {
      const scopedDueDates = scopeToUser(exampleDueDatesData, '101')
      equal(scopedDueDates[201].due_at, '2015-05-04T12:00:00Z')
      equal(scopedDueDates[201].grading_period_id, '701')
      equal(scopedDueDates[201].in_closed_grading_period, true)
      equal(scopedDueDates[202].due_at, '2015-06-04T12:00:00Z')
      equal(scopedDueDates[202].grading_period_id, '702')
      equal(scopedDueDates[202].in_closed_grading_period, false)
    })

    test('excludes assignments not assigned to the given user', () => {
      const scopedDueDates = scopeToUser(exampleDueDatesData, '102')
      deepEqual(_.keys(scopedDueDates), ['201'])
      equal(scopedDueDates[201].due_at, '2015-05-05T12:00:00Z')
      equal(scopedDueDates[201].grading_period_id, '701')
      equal(scopedDueDates[201].in_closed_grading_period, true)
    })
  })

  QUnit.module('.updateWithSubmissions', hooks => {
    let effectiveDueDates
    let submissions

    hooks.beforeEach(() => {
      effectiveDueDates = {
        2301: {
          1101: {
            due_at: '2015-02-02T12:00:00Z',
            grading_period_id: '1401',
            in_closed_grading_period: true,
          },
          1103: {
            due_at: '2015-02-02T12:00:00Z',
            grading_period_id: '1401',
            in_closed_grading_period: true,
          },
        },
        2303: {
          1101: {
            due_at: '2015-04-02T12:00:00Z',
            grading_period_id: '1402',
            in_closed_grading_period: false,
          },
        },
      }
      submissions = [
        {assignment_id: '2301', user_id: '1101', cached_due_date: '2015-02-01T12:00:00Z'},
        {assignment_id: '2302', user_id: '1101', cached_due_date: '2015-04-01T12:00:00Z'},
        {assignment_id: '2302', user_id: '1102', cached_due_date: '2015-04-02T12:00:00Z'},
      ]
    })

    const gradingPeriods = [
      {
        id: '1403',
        closeDate: timezone.parse('2015-07-08T12:00:00Z'),
        endDate: timezone.parse('2015-07-01T12:00:00Z'),
        isClosed: false,
        startDate: timezone.parse('2015-05-01T12:00:00Z'),
      },
      {
        id: '1401',
        closeDate: timezone.parse('2015-03-08T12:00:00Z'),
        endDate: timezone.parse('2015-03-01T12:00:00Z'),
        isClosed: true,
        startDate: timezone.parse('2015-01-01T12:00:00Z'),
      },
      {
        id: '1402',
        closeDate: timezone.parse('2015-05-08T12:00:00Z'),
        endDate: timezone.parse('2015-05-01T12:00:00Z'),
        isClosed: false,
        startDate: timezone.parse('2015-03-01T12:00:00Z'),
      },
    ]

    test('sets the due_at for each effective due date', () => {
      effectiveDueDates = {}
      updateWithSubmissions(effectiveDueDates, submissions, gradingPeriods)
      equal(effectiveDueDates[2301][1101].due_at, '2015-02-01T12:00:00Z')
      equal(effectiveDueDates[2302][1101].due_at, '2015-04-01T12:00:00Z')
      equal(effectiveDueDates[2302][1102].due_at, '2015-04-02T12:00:00Z')
    })

    test('sets the grading_period_id for each effective due date', () => {
      effectiveDueDates = {}
      updateWithSubmissions(effectiveDueDates, submissions, gradingPeriods)
      strictEqual(effectiveDueDates[2301][1101].grading_period_id, '1401')
      strictEqual(effectiveDueDates[2302][1101].grading_period_id, '1402')
      strictEqual(effectiveDueDates[2302][1102].grading_period_id, '1402')
    })

    test('sets in_closed_grading_period for each effective due date', () => {
      effectiveDueDates = {}
      updateWithSubmissions(effectiveDueDates, submissions, gradingPeriods)
      strictEqual(effectiveDueDates[2301][1101].in_closed_grading_period, true)
      strictEqual(effectiveDueDates[2302][1101].in_closed_grading_period, false)
      strictEqual(effectiveDueDates[2302][1102].in_closed_grading_period, false)
    })

    test('updates existing effective due dates for students', () => {
      updateWithSubmissions(effectiveDueDates, submissions, gradingPeriods)
      equal(effectiveDueDates[2301][1101].due_at, '2015-02-01T12:00:00Z')
      strictEqual(effectiveDueDates[2301][1101].grading_period_id, '1401')
      strictEqual(effectiveDueDates[2301][1101].in_closed_grading_period, true)
    })

    test('preserves effective due dates for unrelated students', () => {
      updateWithSubmissions(effectiveDueDates, submissions, gradingPeriods)
      equal(effectiveDueDates[2301][1103].due_at, '2015-02-02T12:00:00Z')
      strictEqual(effectiveDueDates[2301][1103].grading_period_id, '1401')
      strictEqual(effectiveDueDates[2301][1103].in_closed_grading_period, true)
    })

    test('preserves effective due dates for unrelated assignments', () => {
      updateWithSubmissions(effectiveDueDates, submissions, gradingPeriods)
      equal(effectiveDueDates[2303][1101].due_at, '2015-04-02T12:00:00Z')
      strictEqual(effectiveDueDates[2303][1101].grading_period_id, '1402')
      strictEqual(effectiveDueDates[2303][1101].in_closed_grading_period, false)
    })

    test('uses the last grading period when the cached due date is null', () => {
      effectiveDueDates = {}
      submissions[0].cached_due_date = null
      updateWithSubmissions(effectiveDueDates, submissions, gradingPeriods)
      strictEqual(effectiveDueDates[2301][1101].due_at, null)
      strictEqual(effectiveDueDates[2301][1101].grading_period_id, '1403')
      strictEqual(effectiveDueDates[2301][1101].in_closed_grading_period, false)
    })

    test('uses no grading period when the cached due date is outside any grading period', () => {
      effectiveDueDates = {}
      submissions[0].cached_due_date = '2015-07-02T12:00:00Z'
      updateWithSubmissions(effectiveDueDates, submissions, gradingPeriods)
      strictEqual(effectiveDueDates[2301][1101].due_at, '2015-07-02T12:00:00Z')
      strictEqual(effectiveDueDates[2301][1101].grading_period_id, null)
      strictEqual(effectiveDueDates[2301][1101].in_closed_grading_period, false)
    })

    test('uses no grading period when not given any grading periods', () => {
      effectiveDueDates = {}
      updateWithSubmissions(effectiveDueDates, submissions, undefined)
      strictEqual(effectiveDueDates[2301][1101].due_at, '2015-02-01T12:00:00Z')
      strictEqual(effectiveDueDates[2301][1101].grading_period_id, null)
      strictEqual(effectiveDueDates[2301][1101].in_closed_grading_period, false)
    })
  })
})
