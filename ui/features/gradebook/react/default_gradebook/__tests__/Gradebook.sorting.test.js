/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {createGradebook} from './GradebookSpecHelper'

const assignments = [
  {
    id: '1',
    object: {
      due_at: 1,
      name: 'Abc',
      position: 4,
      points_possible: 1,
      module_ids: [1],
      module_positions: [1],
      assignment_group: {position: 5}
    }
  },
  {
    id: '2',
    object: {
      due_at: 2,
      name: 'Bcd',
      position: 3,
      points_possible: 2,
      module_ids: [2],
      module_positions: [2],
      assignment_group: {position: 6}
    }
  }
]
const assignmentsReversed = [...assignments].reverse()

const contextModules = [
  {id: '1', name: 'Module 1', position: 1},
  {id: '2', name: 'Module 2', position: 2}
]

describe('makeColumnSortFn', () => {
  it('returns wrapped sort function for assignment_group, ascending', () => {
    const gradebook = createGradebook()
    const sortFn = gradebook.makeColumnSortFn({
      sortType: '__default__',
      direction: 'ascending'
    })

    let results = [...assignments].sort(sortFn)
    expect(results[0].object.assignment_group.position).toBe(5)
    expect(results[1].object.assignment_group.position).toBe(6)

    results = [...assignmentsReversed].sort(sortFn)
    expect(results[0].object.assignment_group.position).toBe(5)
    expect(results[1].object.assignment_group.position).toBe(6)
  })

  // since "alpha" isn't a type, sorts by assignment position (default)
  it('returns wrapped sort function for alpha, descending', () => {
    const gradebook = createGradebook()
    const sortFn = gradebook.makeColumnSortFn({
      sortType: 'alpha',
      direction: 'descending'
    })

    let results = [...assignments].sort(sortFn)
    expect(results[0].id).toBe('2')
    expect(results[1].id).toBe('1')

    results = [...assignmentsReversed].sort(sortFn)
    expect(results[0].id).toBe('2')
    expect(results[1].id).toBe('1')
  })

  it('returns wrapped sort function for name, ascending', () => {
    const gradebook = createGradebook()
    const sortFn = gradebook.makeColumnSortFn({
      sortType: 'name',
      direction: 'ascending'
    })

    let results = [...assignments].sort(sortFn)
    expect(results[0].object.name).toBe('Abc')
    expect(results[1].object.name).toBe('Bcd')

    results = [...assignmentsReversed].sort(sortFn)
    expect(results[0].object.name).toBe('Abc')
    expect(results[1].object.name).toBe('Bcd')
  })

  it('returns wrapped sort function for name, descending', () => {
    const gradebook = createGradebook()
    const sortFn = gradebook.makeColumnSortFn({
      sortType: 'name',
      direction: 'descending'
    })

    let results = [...assignments].sort(sortFn)
    expect(results[0].object.name).toBe('Bcd')
    expect(results[1].object.name).toBe('Abc')

    results = [...assignmentsReversed].sort(sortFn)
    expect(results[0].object.name).toBe('Bcd')
    expect(results[1].object.name).toBe('Abc')
  })

  it('returns wrapped sort function for due_date, ascending', () => {
    const gradebook = createGradebook()
    const sortFn = gradebook.makeColumnSortFn({sortType: 'due_date', direction: 'ascending'})

    let results = [...assignments].sort(sortFn)
    expect(results[0].object.due_at).toBe(1)
    expect(results[1].object.due_at).toBe(2)

    results = [...assignmentsReversed].sort(sortFn)
    expect(results[0].object.due_at).toBe(1)
    expect(results[1].object.due_at).toBe(2)
  })

  it('returns wrapped sort function for due_date, descending', () => {
    const gradebook = createGradebook()
    const sortFn = gradebook.makeColumnSortFn({sortType: 'due_date', direction: 'descending'})

    let results = [...assignments].sort(sortFn)
    expect(results[0].object.due_at).toBe(2)
    expect(results[1].object.due_at).toBe(1)

    results = [...assignmentsReversed].sort(sortFn)
    expect(results[0].object.due_at).toBe(2)
    expect(results[1].object.due_at).toBe(1)
  })

  it('returns wrapped sort function for points, ascending', () => {
    const gradebook = createGradebook()
    const sortFn = gradebook.makeColumnSortFn({sortType: 'points', direction: 'ascending'})

    let results = [...assignments].sort(sortFn)
    expect(results[0].object.points_possible).toBe(1)
    expect(results[1].object.points_possible).toBe(2)

    results = [...assignmentsReversed].sort(sortFn)
    expect(results[0].object.points_possible).toBe(1)
    expect(results[1].object.points_possible).toBe(2)
  })

  it('returns wrapped sort function for points, descending', () => {
    const gradebook = createGradebook()
    const sortFn = gradebook.makeColumnSortFn({sortType: 'points', direction: 'descending'})

    let results = [...assignments].sort(sortFn)
    expect(results[0].object.points_possible).toBe(2)
    expect(results[1].object.points_possible).toBe(1)

    results = [...assignmentsReversed].sort(sortFn)
    expect(results[0].object.points_possible).toBe(2)
    expect(results[1].object.points_possible).toBe(1)
  })

  it('returns wrapped sort function for module_position, ascending', () => {
    const gradebook = createGradebook()
    gradebook.setContextModules(contextModules)
    const sortFn = gradebook.makeColumnSortFn({sortType: 'module_position', direction: 'ascending'})

    let results = [...assignments].sort(sortFn)
    expect(results[0].object.module_positions[0]).toBe(1)
    expect(results[1].object.module_positions[0]).toBe(2)

    results = [...assignmentsReversed].sort(sortFn)
    expect(results[0].object.module_positions[0]).toBe(1)
    expect(results[1].object.module_positions[0]).toBe(2)
  })

  it('returns wrapped sort function for module_position, descending', () => {
    const gradebook = createGradebook()
    gradebook.setContextModules(contextModules)
    const sortFn = gradebook.makeColumnSortFn({
      sortType: 'module_position',
      direction: 'descending'
    })

    let results = [...assignments].sort(sortFn)
    expect(results[0].object.module_positions[0]).toBe(2)
    expect(results[1].object.module_positions[0]).toBe(1)

    results = [...assignmentsReversed].sort(sortFn)
    expect(results[0].object.module_positions[0]).toBe(2)
    expect(results[1].object.module_positions[0]).toBe(1)
  })
})

describe('Gradebook#makeCompareAssignmentCustomOrderFn', () => {
  it('returns position difference if both are defined in the index', () => {
    const sortOrder = {customOrder: ['foo', 'bar']}
    const gradeBook = createGradebook()
    const sortFn = gradeBook.makeCompareAssignmentCustomOrderFn(sortOrder)

    const a = {id: 'foo'}
    const b = {id: 'bar'}
    expect(sortFn(a, b)).toBe(-1)
  })

  it('returns -1 if the first arg is in the order and the second one is not', () => {
    const sortOrder = {customOrder: ['foo', 'bar']}
    const gradeBook = createGradebook()
    const sortFn = gradeBook.makeCompareAssignmentCustomOrderFn(sortOrder)

    const a = {id: 'foo'}
    const b = {id: 'NO'}
    expect(sortFn(a, b)).toBe(-1)
  })

  it('returns 1 if the second arg is in the order and the first one is not', () => {
    const sortOrder = {customOrder: ['foo', 'bar']}
    const gradeBook = createGradebook()
    const sortFn = gradeBook.makeCompareAssignmentCustomOrderFn(sortOrder)

    const a = {id: 'NO'}
    const b = {id: 'bar'}
    expect(sortFn(a, b)).toBe(1)
  })

  it('falls back to object id for the indexes if field is not in the map', () => {
    const sortOrder = {customOrder: ['5', '11']}
    const gradeBook = createGradebook()
    const sortFn = gradeBook.makeCompareAssignmentCustomOrderFn(sortOrder)

    const a = {id: 'NO', object: {id: 5}}
    const b = {id: 'NOPE', object: {id: 11}}
    expect(sortFn(a, b)).toBe(-1)
  })
})
