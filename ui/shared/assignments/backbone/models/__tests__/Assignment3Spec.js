/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import 'jquery-migrate'
import '@canvas/jquery/jquery.ajaxJSON'
import Assignment from '../Assignment'
import DateGroup from '@canvas/date-group/backbone/models/DateGroup'
import fakeENV from '@canvas/test-utils/fakeENV'

QUnit.module('Assignment#peerReviews')

test('returns the peer_reviews on the record if no args passed', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('peer_reviews', false)
  equal(assignment.peerReviews(), false)
})

test("sets the record's peer_reviews if args passed", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('peer_reviews', false)
  assignment.peerReviews(true)
  equal(assignment.peerReviews(), true)
})

QUnit.module('Assignment#automaticPeerReviews')

test('returns the automatic_peer_reviews on the model if no args passed', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('automatic_peer_reviews', false)
  equal(assignment.automaticPeerReviews(), false)
})

test('sets the automatic_peer_reviews on the record if args passed', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('automatic_peer_reviews', false)
  assignment.automaticPeerReviews(true)
  equal(assignment.automaticPeerReviews(), true)
})

QUnit.module('Assignment#notifyOfUpdate')

test("returns record's notifyOfUpdate if no args passed", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('notify_of_update', false)
  equal(assignment.notifyOfUpdate(), false)
})

test("sets record's notifyOfUpdate if args passed", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.notifyOfUpdate(false)
  equal(assignment.notifyOfUpdate(), false)
})

QUnit.module('Assignment#multipleDueDates')

test('checks for multiple due dates from assignment overrides', () => {
  const assignment = new Assignment({
    all_dates: [{title: 'Winter'}, {title: 'Summer'}],
  })
  ok(assignment.multipleDueDates())
})

test('checks for no multiple due dates from assignment overrides', () => {
  const assignment = new Assignment()
  ok(!assignment.multipleDueDates())
})

QUnit.module('Assignment#allDates')

test('gets the due dates from the assignment overrides', () => {
  const dueAt = new Date('2013-08-20T11:13:00')
  const dates = [
    new DateGroup({
      due_at: dueAt,
      title: 'Everyone',
    }),
  ]
  const assignment = new Assignment({all_dates: dates})
  const allDates = assignment.allDates()
  const first = allDates[0]
  equal(`${first.dueAt}`, `${dueAt}`)
  equal(first.dueFor, 'Everyone')
})

test('gets empty due dates when there are no dates', () => {
  const assignment = new Assignment()
  deepEqual(assignment.allDates(), [])
})

QUnit.module('Assignment#inGradingPeriod', {
  setup() {
    this.gradingPeriod = {
      id: '1',
      title: 'Fall',
      startDate: new Date('2013-07-01T11:13:00'),
      endDate: new Date('2013-10-01T11:13:00'),
      closeDate: new Date('2013-10-05T11:13:00'),
      isLast: true,
      isClosed: true,
    }
    this.dateInPeriod = new Date('2013-08-20T11:13:00')
    this.dateOutsidePeriod = new Date('2013-01-20T11:13:00')
  },
})

test('returns true if the assignment has a due_at in the given period', function () {
  const assignment = new Assignment()
  assignment.set('due_at', this.dateInPeriod)
  equal(assignment.inGradingPeriod(this.gradingPeriod), true)
})

test('returns false if the assignment has a due_at outside the given period', function () {
  const assignment = new Assignment()
  assignment.set('due_at', this.dateOutsidePeriod)
  equal(assignment.inGradingPeriod(this.gradingPeriod), false)
})

test('returns true if the assignment has a date group in the given period', function () {
  const dates = [
    new DateGroup({
      due_at: this.dateInPeriod,
      title: 'Everyone',
    }),
  ]
  const assignment = new Assignment({all_dates: dates})
  equal(assignment.inGradingPeriod(this.gradingPeriod), true)
})

test('returns false if the assignment does not have a date group in the given period', function () {
  const dates = [
    new DateGroup({
      due_at: this.dateOutsidePeriod,
      title: 'Everyone',
    }),
  ]
  const assignment = new Assignment({all_dates: dates})
  equal(assignment.inGradingPeriod(this.gradingPeriod), false)
})

QUnit.module('Assignment#singleSectionDueDate', {
  setup() {
    fakeENV.setup()
  },
  teardown() {
    fakeENV.teardown()
  },
})

test('gets the due date for section instead of null', () => {
  const dueAt = new Date('2013-11-27T11:01:00Z')
  const assignment = new Assignment({
    all_dates: [
      {
        due_at: null,
        title: 'Everyone',
      },
      {
        due_at: dueAt,
        title: 'Summer',
      },
    ],
  })
  sandbox.stub(assignment, 'multipleDueDates').returns(false)
  equal(assignment.singleSectionDueDate(), dueAt.toISOString())
})

test('returns due_at when only one date/section are present', () => {
  const date = Date.now()
  const assignment = new Assignment({name: 'Taco party!'})
  assignment.set('due_at', date)
  equal(assignment.singleSectionDueDate(), assignment.dueAt())
  ENV.PERMISSIONS = {manage: false}
  equal(assignment.singleSectionDueDate(), assignment.dueAt())
  ENV.PERMISSIONS = {}
})

QUnit.module('Assignment#omitFromFinalGrade')

test("gets the record's omit_from_final_grade boolean", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('omit_from_final_grade', true)
  ok(assignment.omitFromFinalGrade())
})

test("sets the record's omit_from_final_grade boolean if args passed", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.omitFromFinalGrade(true)
  ok(assignment.omitFromFinalGrade())
})

QUnit.module('Assignment#hideInGradeBook')

test("gets the record's hide_in_gradebook boolean", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('hide_in_gradebook', true)
  ok(assignment.hideInGradebook())
})

test("sets the record's hide_in_gradebook boolean if args passed", () => {
  const assignment = new Assignment({name: 'bar'})
  assignment.hideInGradebook(true)
  ok(assignment.hideInGradebook())
})
