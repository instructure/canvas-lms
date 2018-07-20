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

test('Grid.Util._toRow', () => {
  Grid.students = {1: {}}
  Grid.sections = {1: {}}
  const rollup = {
    links: { section: "1", user: "1" },
    scores: [{ score: "3", hide_points: true, links: { outcome:"2" } }]
  }
  ok(
    isEqual(Grid.Util._toRow([rollup], null).outcome_2, { score: "3", hide_points: true }),
    'correctly returns an object with a score and hide_points for a cell'
  )
})

test('Grid.Util.toRows', () => {
  Grid.students = {1: {id: 1}, 2: {id: 2}, 3: {id: 3}}
  Grid.sections = {1: {}}
  const rollups = [
    {
      links: { section: "1", user: "3" }
    },
    {
      links: { section: "1", user: "1" }
    },
    {
      links: { section: "1", user: "2" }
    }
  ]
  ok(
    isEqual(Grid.Util.toRows(rollups).map((r) => r.student.id), [3, 1, 2]),
    'returns rows in the same user order as rollups'
  )
})

test('Grid.View.masteryDetails', () => {
  const outcome = {mastery_points: 5, points_possible: 10}
  const spy = sinon.spy(Grid.View, 'legacyMasteryDetails')
  Grid.View.masteryDetails(10, outcome)
  ok(
    spy.calledOnce,
    'calls legacyMasteryDetails when no custom ratings defined'
  )
  Grid.ratings = [
    {points: 10, color: '00ff00', description: 'great'},
    {points:  5, color: '0000ff', description: 'OK'},
    {points:  0, color: 'ff0000', description: 'turrable'}
  ]
  ok(
    isEqual(Grid.View.masteryDetails(10, outcome), ['rating_0', '#00ff00', 'great']),
    'returns color of first rating'
  )
  ok(
    isEqual(Grid.View.masteryDetails(9, outcome), ['rating_1', '#0000ff', 'OK']),
    'returns color of second rating'
  )
  ok(
    isEqual(Grid.View.masteryDetails(5, outcome), ['rating_1', '#0000ff', 'OK']),
    'returns color of second rating'
  )
  ok(
    isEqual(Grid.View.masteryDetails(4, outcome), ['rating_2', '#ff0000', 'turrable']),
    'returns color of third rating'
  )
  ok(
    isEqual(Grid.View.masteryDetails(0, outcome), ['rating_2', '#ff0000', 'turrable']),
    'returns color of third rating'
  )
})

test('Grid.View.masteryDetails with scaling', () => {
  const outcome = {points_possible: 5}
  Grid.ratings = [
    {points: 10, color: '00ff00', description: 'great'},
    {points:  5, color: '0000ff', description: 'OK'},
    {points:  0, color: 'ff0000', description: 'turrable'}
  ]
  ok(
    isEqual(Grid.View.masteryDetails(5, outcome), ['rating_0', '#00ff00', 'great']),
    'returns color of first rating'
  )
  ok(
    isEqual(Grid.View.masteryDetails(2.5, outcome), ['rating_1', '#0000ff', 'OK']),
    'returns color of second rating'
  )
  ok(
    isEqual(Grid.View.masteryDetails(0, outcome), ['rating_2', '#ff0000', 'turrable']),
    'returns color of third rating'
  )
})

test('Grid.View.masteryDetails with scaling (points_possible 0)', () => {
  const outcome = {mastery_points: 5, points_possible: 0}
  Grid.ratings = [
    {points: 10, color: '00ff00', description: 'great'},
    {points:  5, color: '0000ff', description: 'OK'},
    {points:  0, color: 'ff0000', description: 'turrable'}
  ]
  ok(
    isEqual(Grid.View.masteryDetails(5, outcome), ['rating_0', '#00ff00', 'great']),
    'returns color of first rating'
  )
  ok(
    isEqual(Grid.View.masteryDetails(2.5, outcome), ['rating_1', '#0000ff', 'OK']),
    'returns color of second rating'
  )
  ok(
    isEqual(Grid.View.masteryDetails(0, outcome), ['rating_2', '#ff0000', 'turrable']),
    'returns color of third rating'
  )
})

test('Grid.View.legacyMasteryDetails', () => {
  const outcome = {mastery_points: 5}
  ok(
    isEqual(Grid.View.legacyMasteryDetails(8, outcome), ['rating_0', '#127A1B', 'Exceeds Mastery']),
    'returns "exceeds" if 150% or more of mastery score'
  )
  ok(
    isEqual(Grid.View.legacyMasteryDetails(5, outcome), ['rating_1', '#00AC18', 'Meets Mastery']),
    'returns "mastery" if equal to mastery score'
  )
  ok(
    isEqual(Grid.View.legacyMasteryDetails(7, outcome), ['rating_1', '#00AC18', 'Meets Mastery']),
    'returns "mastery" if above mastery score'
  )
  ok(
    isEqual(Grid.View.legacyMasteryDetails(3, outcome), ['rating_2', '#FC5E13', 'Near Mastery']),
    'returns "near-mastery" if half of mastery score or greater'
  )
  ok(
    isEqual(Grid.View.legacyMasteryDetails(1, outcome), ['rating_3', '#EE0612', 'Well Below Mastery']),
    'returns "remedial" if less than half of mastery score'
  )
})

test('Grid.Util.toColumns for xss', () => {
  const outcome = {
    id: 1,
    title: '<script>'
  }
  const columns = Grid.Util.toColumns([outcome], [])
  ok(isEqual(columns[1].name, '&lt;script&gt;'))
})

test('Grid.Util._studentColumn does not modify default options', () => {
  Grid.Util._studentColumn()
  ok(isEqual(121, Grid.Util.COLUMN_OPTIONS.width))
})

test('Grid.Util.toColumns hasResults', () => {
  const outcomes = [
    {
      id: "1"

    },
    {
      id: "2"
    }
  ]
  const rollup = {
    links: { section: "1", user: "1" },
    scores: [{ score: "3", hide_points: true, links: { outcome:"2" } }]
  }
  const columns = Grid.Util.toColumns(outcomes, [rollup])
  ok(isEqual(columns[1].hasResults, false))
  ok(isEqual(columns[2].hasResults, true))
})
