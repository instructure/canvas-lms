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
import {isEqual} from 'lodash'
import Grid from '..'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('OutcomeGradebookGrid', () => {
  beforeEach(() => {
    fakeENV.setup()
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  test('Grid.Math.mean', () => {
    const subject = [1, 1, 2, 4, 5]
    expect(Grid.Math.mean(subject)).toBeCloseTo(2.6)
    expect(Grid.Math.mean(subject, true)).toBe(3)
    expect(Grid.Math.mean([5, 12, 2])).toBeCloseTo(6.33)
  })

  test('Grid.Util._toRow', () => {
    Grid.students = {1: {}}
    Grid.sections = {1: {}}
    const rollup = {
      links: {section: '1', user: '1'},
      scores: [{score: '3', hide_points: true, links: {outcome: '2'}}],
    }
    expect(
      isEqual(Grid.Util._toRow([rollup], null).outcome_2, {score: '3', hide_points: true})
    ).toBe(true)
  })

  test('Grid.Util.toRows', () => {
    Grid.students = {1: {id: 1}, 2: {id: 2}, 3: {id: 3}}
    Grid.sections = {1: {}}
    const rollups = [
      {links: {section: '1', user: '3'}},
      {links: {section: '1', user: '1'}},
      {links: {section: '1', user: '2'}},
    ]
    expect(Grid.Util.toRows(rollups).map(r => r.student.id)).toEqual([3, 1, 2])
  })

  test('Grid.View.masteryDetails', () => {
    const outcome = {mastery_points: 5, points_possible: 10}
    const spy = jest.spyOn(Grid.View, 'legacyMasteryDetails')
    Grid.View.masteryDetails(10, outcome)
    expect(spy).toHaveBeenCalledTimes(1)
    Grid.ratings = [
      {points: 10, color: '00ff00', description: 'great'},
      {points: 5, color: '0000ff', description: 'OK'},
      {points: 0, color: 'ff0000', description: 'turrable'},
    ]
    expect(Grid.View.masteryDetails(10, outcome)).toEqual(['rating_0', '#00ff00', 'great'])
    expect(Grid.View.masteryDetails(9, outcome)).toEqual(['rating_1', '#0000ff', 'OK'])
    expect(Grid.View.masteryDetails(5, outcome)).toEqual(['rating_1', '#0000ff', 'OK'])
    expect(Grid.View.masteryDetails(4, outcome)).toEqual(['rating_2', '#ff0000', 'turrable'])
    expect(Grid.View.masteryDetails(0, outcome)).toEqual(['rating_2', '#ff0000', 'turrable'])
  })

  test('Grid.View.masteryDetails with scaling', () => {
    const outcome = {points_possible: 5}
    Grid.ratings = [
      {points: 10, color: '00ff00', description: 'great'},
      {points: 5, color: '0000ff', description: 'OK'},
      {points: 0, color: 'ff0000', description: 'turrable'},
    ]
    expect(Grid.View.masteryDetails(5, outcome)).toEqual(['rating_0', '#00ff00', 'great'])
    expect(Grid.View.masteryDetails(2.5, outcome)).toEqual(['rating_1', '#0000ff', 'OK'])
    expect(Grid.View.masteryDetails(0, outcome)).toEqual(['rating_2', '#ff0000', 'turrable'])
  })

  test('Grid.View.masteryDetails with scaling (points_possible 0)', () => {
    const outcome = {mastery_points: 5, points_possible: 0}
    Grid.ratings = [
      {points: 10, color: '00ff00', description: 'great'},
      {points: 5, color: '0000ff', description: 'OK'},
      {points: 0, color: 'ff0000', description: 'turrable'},
    ]
    expect(Grid.View.masteryDetails(5, outcome)).toEqual(['rating_0', '#00ff00', 'great'])
    expect(Grid.View.masteryDetails(2.5, outcome)).toEqual(['rating_1', '#0000ff', 'OK'])
    expect(Grid.View.masteryDetails(0, outcome)).toEqual(['rating_2', '#ff0000', 'turrable'])
  })

  test('Grid.View.legacyMasteryDetails', () => {
    const outcome = {mastery_points: 5}
    expect(Grid.View.legacyMasteryDetails(8, outcome)).toEqual([
      'rating_0',
      '#127A1B',
      'Exceeds Mastery',
    ])
    expect(Grid.View.legacyMasteryDetails(5, outcome)).toEqual([
      'rating_1',
      '#0B874B',
      'Meets Mastery',
    ])
    expect(Grid.View.legacyMasteryDetails(7, outcome)).toEqual([
      'rating_1',
      '#0B874B',
      'Meets Mastery',
    ])
    expect(Grid.View.legacyMasteryDetails(3, outcome)).toEqual([
      'rating_2',
      '#FC5E13',
      'Near Mastery',
    ])
    expect(Grid.View.legacyMasteryDetails(1, outcome)).toEqual([
      'rating_3',
      '#E0061F',
      'Well Below Mastery',
    ])
  })

  test('Grid.Util.toColumns for xss', () => {
    const outcome = {id: 1, title: '<script>'}
    const columns = Grid.Util.toColumns([outcome], [])
    expect(columns[1].name).toEqual('&lt;script&gt;')
  })

  test('Grid.Util._studentColumn does not modify default options', () => {
    Grid.Util._studentColumn()
    expect(Grid.Util.COLUMN_OPTIONS.width).toBe(121)
  })

  test('Grid.Util.toColumns hasResults', () => {
    const outcomes = [{id: '1'}, {id: '2'}]
    const rollup = {
      links: {section: '1', user: '1'},
      scores: [{score: '3', hide_points: true, links: {outcome: '2'}}],
    }
    const columns = Grid.Util.toColumns(outcomes, [rollup])
    expect(columns[1].hasResults).toBe(false)
    expect(columns[2].hasResults).toBe(true)
  })
})
