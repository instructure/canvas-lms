/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import {isEqual, pluck} from 'underscore'
import Grid from 'compiled/gradezilla/OutcomeGradebookGrid'
import fakeENV from 'helpers/fakeENV'
import 'i18n!gradezilla'

QUnit.module('OutcomeGradebookGrid', {
  setup() {
    fakeENV.setup()
  },
  teardown() {
    fakeENV.teardown()
  }
})

test('Grid.Math.mean', () => {
  const subject = [1, 1, 2, 4, 5]
  ok(Grid.Math.mean(subject) === 2.6, 'returns a proper average')
  ok(Grid.Math.mean(subject, true) === 3, 'optionally rounds result value')
  ok(Grid.Math.mean([5, 12, 2]) === 6.33, 'rounds to two places')
})

test('Grid.Math.median', () => {
  const odd = [1, 3, 2, 5, 4]
  const even = [1, 3, 2, 6, 5, 4]
  ok(Grid.Math.median(odd) === 3, 'properly finds median on odd datasets')
  ok(Grid.Math.median(even) === 3.5, 'properly finds median on even datasets')
})

test('Grid.Math.mode', () => {
  const single = [1, 1, 1, 3, 5]
  const multiple = [1, 1, 2, 2, 3, 5]
  ok(Grid.Math.mode(single) === 1, 'returns mode when it is a single node')
  ok(Grid.Math.mode(multiple) === 2, 'averages multiple modes to return a single result')
})

test('Grid.View.masteryColor', () => {
  const outcome = {mastery_points: 5, points_possible: 10}
  const spy = sinon.spy(Grid.View, 'legacyMasteryColor')
  Grid.View.masteryColor(10, outcome)
  ok(
    spy.calledOnce,
    'calls legacyMasteryColor when no custom ratings defined'
  )
  Grid.ratings = [
    {points: 10, color: '00ff00'},
    {points:  5, color: '0000ff'},
    {points:  0, color: 'ff0000'}
  ]
  ok(
    isEqual(Grid.View.masteryColor(10, outcome), ['rating_0', '#00ff00']),
    'returns color of first rating'
  )
  ok(
    isEqual(Grid.View.masteryColor(9, outcome), ['rating_1', '#0000ff']),
    'returns color of second rating'
  )
  ok(
    isEqual(Grid.View.masteryColor(5, outcome), ['rating_1', '#0000ff']),
    'returns color of second rating'
  )
  ok(
    isEqual(Grid.View.masteryColor(4, outcome), ['rating_2', '#ff0000']),
    'returns color of third rating'
  )
  ok(
    isEqual(Grid.View.masteryColor(0, outcome), ['rating_2', '#ff0000']),
    'returns color of third rating'
  )
})

test('Grid.View.masteryColor with scaling', () => {
  const outcome = {points_possible: 5}
  Grid.ratings = [
    {points: 10, color: '00ff00'},
    {points:  5, color: '0000ff'},
    {points:  0, color: 'ff0000'}
  ]
  ok(
    isEqual(Grid.View.masteryColor(5, outcome), ['rating_0', '#00ff00']),
    'returns color of first rating'
  )
  ok(
    isEqual(Grid.View.masteryColor(2.5, outcome), ['rating_1', '#0000ff']),
    'returns color of second rating'
  )
  ok(
    isEqual(Grid.View.masteryColor(0, outcome), ['rating_2', '#ff0000']),
    'returns color of third rating'
  )
})

test('Grid.View.masteryColor with scaling (points_possible 0)', () => {
  const outcome = {mastery_points: 5, points_possible: 0}
  Grid.ratings = [
    {points: 10, color: '00ff00'},
    {points:  5, color: '0000ff'},
    {points:  0, color: 'ff0000'}
  ]
  ok(
    isEqual(Grid.View.masteryColor(5, outcome), ['rating_0', '#00ff00']),
    'returns color of first rating'
  )
  ok(
    isEqual(Grid.View.masteryColor(2.5, outcome), ['rating_1', '#0000ff']),
    'returns color of second rating'
  )
  ok(
    isEqual(Grid.View.masteryColor(0, outcome), ['rating_2', '#ff0000']),
    'returns color of third rating'
  )
})

test('Grid.View.legacyMasteryColor', () => {
  const outcome = {mastery_points: 5}
  ok(
    isEqual(Grid.View.legacyMasteryColor(8, outcome), ['rating_0', '#6a843f']),
    'returns "exceeds" if 150% or more of mastery score'
  )
  ok(
    isEqual(Grid.View.legacyMasteryColor(5, outcome), ['rating_1', '#8aac53']),
    'returns "mastery" if equal to mastery score'
  )
  ok(
    isEqual(Grid.View.legacyMasteryColor(7, outcome), ['rating_1', '#8aac53']),
    'returns "mastery" if above mastery score'
  )
  ok(
    isEqual(Grid.View.legacyMasteryColor(3, outcome), ['rating_2', '#e0d773']),
    'returns "near-mastery" if half of mastery score or greater'
  )
  ok(
    isEqual(Grid.View.legacyMasteryColor(1, outcome), ['rating_3', '#df5b59']),
    'returns "remedial" if less than half of mastery score'
  )
})

test('Grid.Events.sort', () => {
  const rows = [
    {
      student: {sortable_name: 'Draper, Don'},
      outcome_1: 3
    },
    {
      student: {sortable_name: 'Olson, Peggy'},
      outcome_1: 4
    },
    {
      student: {sortable_name: 'Campbell, Pete'},
      outcome_1: 3
    }
  ]
  const outcomeSort = rows.sort((a, b) => Grid.Events._sortResults(a, b, true, 'outcome_1'))
  const userSort = rows.sort((a, b) => Grid.Events._sortStudents(a, b, true))
  ok(isEqual([3, 3, 4], pluck(outcomeSort, 'outcome_1')), 'sorts by result value')
  ok(
    outcomeSort.map(r => r.student.sortable_name)[0] === 'Campbell, Pete',
    'result sort falls back to sortable name'
  )
  ok(
    isEqual(userSort.map(r => r.student.sortable_name), [
      'Campbell, Pete',
      'Draper, Don',
      'Olson, Peggy'
    ]),
    'sorts by student name'
  )
})

test('Grid.Util.toColumns for xss', () => {
  const outcome = {
    id: 1,
    title: '<script>'
  }
  const columns = Grid.Util.toColumns([outcome])
  ok(isEqual(columns[1].name, '&lt;script&gt;'))
})
