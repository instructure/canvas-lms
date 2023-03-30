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
import {
  compareAssignmentNames,
  compareAssignmentPointsPossible,
  compareAssignmentPositions,
  isDefaultSortOrder,
  localeSort,
  makeCompareAssignmentCustomOrderFn,
  wrapColumnSortFn,
} from '../Gradebook.sorting'
import type {GradebookStudent} from '../gradebook.d'
import type {GridColumn} from '../grid.d'

const assignments = [
  {
    id: '1',
    object: {
      id: '1',
      due_at: '2022-10-01T05:59:59Z',
      name: 'Abc',
      position: 4,
      points_possible: 1,
      module_ids: ['1'],
      module_positions: [1],
      assignment_group: {position: 5},
    },
  },
  {
    id: '2',
    object: {
      id: '2',
      due_at: '2022-10-01T06:59:59Z',
      name: 'Bcd',
      position: 3,
      points_possible: 2,
      module_ids: ['2'],
      module_positions: [2],
      assignment_group: {position: 6},
    },
  },
] as GridColumn[]
const assignmentsReversed = [...assignments].reverse()

const contextModules = [
  {id: '1', name: 'Module 1', position: 1},
  {id: '2', name: 'Module 2', position: 2},
]

describe('makeColumnSortFn', () => {
  it('returns wrapped sort function for assignment_group, ascending', () => {
    const gradebook = createGradebook()
    const sortFn = gradebook.makeColumnSortFn({
      sortType: '__default__',
      direction: 'ascending',
    })

    let results = [...assignments].sort(sortFn)
    expect(results[0].object?.assignment_group?.position).toBe(5)
    expect(results[1].object?.assignment_group?.position).toBe(6)

    results = [...assignmentsReversed].sort(sortFn)
    expect(results[0].object?.assignment_group?.position).toBe(5)
    expect(results[1].object?.assignment_group?.position).toBe(6)
  })

  // since "alpha" isn't a type, sorts by assignment position (default)
  it('returns wrapped sort function for alpha, descending', () => {
    const gradebook = createGradebook()
    const sortFn = gradebook.makeColumnSortFn({
      sortType: 'alpha',
      direction: 'descending',
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
      direction: 'ascending',
    })

    let results = [...assignments].sort(sortFn)
    expect(results[0].object?.name).toBe('Abc')
    expect(results[1].object?.name).toBe('Bcd')

    results = [...assignmentsReversed].sort(sortFn)
    expect(results[0].object?.name).toBe('Abc')
    expect(results[1].object?.name).toBe('Bcd')
  })

  it('returns wrapped sort function for name, descending', () => {
    const gradebook = createGradebook()
    const sortFn = gradebook.makeColumnSortFn({
      sortType: 'name',
      direction: 'descending',
    })

    let results = [...assignments].sort(sortFn)
    expect(results[0].object?.name).toBe('Bcd')
    expect(results[1].object?.name).toBe('Abc')

    results = [...assignmentsReversed].sort(sortFn)
    expect(results[0].object?.name).toBe('Bcd')
    expect(results[1].object?.name).toBe('Abc')
  })

  it('returns wrapped sort function for due_date, ascending', () => {
    const gradebook = createGradebook()
    const sortFn = gradebook.makeColumnSortFn({sortType: 'due_date', direction: 'ascending'})

    let results = [...assignments].sort(sortFn)
    expect(results[0].object?.due_at).toBe('2022-10-01T05:59:59Z')
    expect(results[1].object?.due_at).toBe('2022-10-01T06:59:59Z')

    results = [...assignmentsReversed].sort(sortFn)
    expect(results[0].object?.due_at).toBe('2022-10-01T05:59:59Z')
    expect(results[1].object?.due_at).toBe('2022-10-01T06:59:59Z')
  })

  it('returns wrapped sort function for due_date, descending', () => {
    const gradebook = createGradebook()
    const sortFn = gradebook.makeColumnSortFn({sortType: 'due_date', direction: 'descending'})

    let results = [...assignments].sort(sortFn)
    expect(results[0].object?.due_at).toBe('2022-10-01T06:59:59Z')
    expect(results[1].object?.due_at).toBe('2022-10-01T05:59:59Z')

    results = [...assignmentsReversed].sort(sortFn)
    expect(results[0].object?.due_at).toBe('2022-10-01T06:59:59Z')
    expect(results[1].object?.due_at).toBe('2022-10-01T05:59:59Z')
  })

  it('returns wrapped sort function for points, ascending', () => {
    const gradebook = createGradebook()
    const sortFn = gradebook.makeColumnSortFn({sortType: 'points', direction: 'ascending'})

    let results = [...assignments].sort(sortFn)
    expect(results[0].object?.points_possible).toBe(1)
    expect(results[1].object?.points_possible).toBe(2)

    results = [...assignmentsReversed].sort(sortFn)
    expect(results[0].object?.points_possible).toBe(1)
    expect(results[1].object?.points_possible).toBe(2)
  })

  it('returns wrapped sort function for points, descending', () => {
    const gradebook = createGradebook()
    const sortFn = gradebook.makeColumnSortFn({sortType: 'points', direction: 'descending'})

    let results = [...assignments].sort(sortFn)
    expect(results[0].object?.points_possible).toBe(2)
    expect(results[1].object?.points_possible).toBe(1)

    results = [...assignmentsReversed].sort(sortFn)
    expect(results[0].object?.points_possible).toBe(2)
    expect(results[1].object?.points_possible).toBe(1)
  })

  it('returns wrapped sort function for module_position, ascending', () => {
    const gradebook = createGradebook()
    gradebook.setContextModules(contextModules)
    const sortFn = gradebook.makeColumnSortFn({sortType: 'module_position', direction: 'ascending'})

    let results = [...assignments].sort(sortFn)
    expect(results[0].object?.module_positions?.[0]).toBe(1)
    expect(results[1].object?.module_positions?.[0]).toBe(2)

    results = [...assignmentsReversed].sort(sortFn)
    expect(results[0].object?.module_positions?.[0]).toBe(1)
    expect(results[1].object?.module_positions?.[0]).toBe(2)
  })

  it('returns wrapped sort function for module_position, descending', () => {
    const gradebook = createGradebook()
    gradebook.setContextModules(contextModules)
    const sortFn = gradebook.makeColumnSortFn({
      sortType: 'module_position',
      direction: 'descending',
    })

    let results = [...assignments].sort(sortFn)
    expect(results[0].object?.module_positions?.[0]).toBe(2)
    expect(results[1].object?.module_positions?.[0]).toBe(1)

    results = [...assignmentsReversed].sort(sortFn)
    expect(results[0].object?.module_positions?.[0]).toBe(2)
    expect(results[1].object?.module_positions?.[0]).toBe(1)
  })
})

describe('Gradebook#makeCompareAssignmentCustomOrderFn', () => {
  it('returns position difference if both are defined in the index', () => {
    const sortOrder = {customOrder: ['foo', 'bar']}
    const sortFn = makeCompareAssignmentCustomOrderFn(sortOrder)

    const a = {id: 'foo'} as GridColumn
    const b = {id: 'bar'} as GridColumn
    expect(sortFn(a, b)).toBe(-1)
  })

  it('returns -1 if the first arg is in the order and the second one is not', () => {
    const sortOrder = {customOrder: ['foo', 'bar']}
    const sortFn = makeCompareAssignmentCustomOrderFn(sortOrder)

    const a = {id: 'foo'} as GridColumn
    const b = {id: 'NO'} as GridColumn
    expect(sortFn(a, b)).toBe(-1)
  })

  it('returns 1 if the second arg is in the order and the first one is not', () => {
    const sortOrder = {customOrder: ['foo', 'bar']}
    const sortFn = makeCompareAssignmentCustomOrderFn(sortOrder)

    const a = {id: 'NO'} as GridColumn
    const b = {id: 'bar'} as GridColumn
    expect(sortFn(a, b)).toBe(1)
  })

  it('falls back to object id for the indexes if field is not in the map', () => {
    const sortOrder = {customOrder: ['5', '11']}
    const sortFn = makeCompareAssignmentCustomOrderFn(sortOrder)

    const a = {id: 'NO', object: {id: '5', position: 1}} as GridColumn
    const b = {id: 'NOPE', object: {id: '11', position: 2}} as GridColumn
    expect(sortFn(a, b)).toBe(-1)
  })
})

describe('compareAssignmentPositions', () => {
  it('sorts by position (1)', () => {
    const a = {object: {position: 1, assignment_group: {position: 1}}}
    const b = {object: {position: 2, assignment_group: {position: 1}}}
    expect([a, b].sort(compareAssignmentPositions)).toStrictEqual([a, b])
  })

  it('sorts by position (2)', () => {
    const a = {object: {position: 1, assignment_group: {position: 1}}}
    const b = {object: {position: 2, assignment_group: {position: 1}}}
    expect([b, a].sort(compareAssignmentPositions)).toStrictEqual([a, b])
  })

  it('sorts by assignment_group.position (1)', () => {
    const a = {object: {position: 2, assignment_group: {position: 1}}}
    const b = {object: {position: 1, assignment_group: {position: 2}}}
    expect([a, b].sort(compareAssignmentPositions)).toStrictEqual([a, b])
  })

  it('sorts by assignment_group.position (2)', () => {
    const a = {object: {position: 2, assignment_group: {position: 1}}}
    const b = {object: {position: 1, assignment_group: {position: 2}}}
    expect([b, a].sort(compareAssignmentPositions)).toStrictEqual([a, b])
  })
})

describe('compareAssignmentPointsPossible', () => {
  it('returns 0 if the points_possible field is the same in both records', function () {
    expect(compareAssignmentPointsPossible(assignments[0], assignments[0])).toStrictEqual(0)
  })

  it('sorts by points_possible', () => {
    let results = [...assignments].sort(compareAssignmentPointsPossible)
    expect(results[0].object?.points_possible).toBe(1)
    expect(results[1].object?.points_possible).toBe(2)

    results = [...assignmentsReversed].sort(compareAssignmentPointsPossible)
    expect(results[0].object?.points_possible).toBe(1)
    expect(results[1].object?.points_possible).toBe(2)
  })
})

describe('wrapColumnSortFn', () => {
  it('returns -1 if second argument is of type total_grade', () => {
    const sortFn = wrapColumnSortFn(jest.fn())
    expect(sortFn({id: '1'} as GridColumn, {id: '2', type: 'total_grade'} as GridColumn)).toBe(-1)
  })

  it('returns 1 if first argument is of type total_grade', () => {
    const sortFn = wrapColumnSortFn(jest.fn())
    expect(sortFn({id: '1', type: 'total_grade'} as GridColumn, {id: '2'} as GridColumn)).toBe(1)
  })

  it('returns 1 if first argument is of type total_grade_override', () => {
    const sortFn = wrapColumnSortFn(jest.fn())
    expect(
      sortFn({id: '1', type: 'total_grade_override'} as GridColumn, {id: '2'} as GridColumn)
    ).toBe(1)
  })

  it('returns -1 if second argument is of type total_grade_override', () => {
    const sortFn = wrapColumnSortFn(jest.fn())
    expect(
      sortFn({id: '1'} as GridColumn, {id: '2', type: 'total_grade_override'} as GridColumn)
    ).toBe(-1)
  })

  it('returns -1 if second argument is an assignment_group and the first is not', () => {
    const sortFn = wrapColumnSortFn(jest.fn())
    expect(sortFn({id: '1'} as GridColumn, {id: '2', type: 'assignment_group'} as GridColumn)).toBe(
      -1
    )
  })

  it('returns 1 if first arg is an assignment_group and second arg is not', () => {
    const sortFn = wrapColumnSortFn(jest.fn())
    expect(sortFn({id: '1', type: 'assignment_group'} as GridColumn, {id: '2'} as GridColumn)).toBe(
      1
    )
  })

  it('returns difference in object.positions if both args are assignement_groups', () => {
    const sortFn = wrapColumnSortFn(jest.fn())
    const a = {id: '1', type: 'assignment_group', object: {position: 10}} as GridColumn
    const b = {id: '2', type: 'assignment_group', object: {position: 5}} as GridColumn

    expect(sortFn(a, b)).toBe(5)
  })

  it('calls wrapped function when either column is not total_grade nor assignment_group', () => {
    const wrappedFn = jest.fn()
    const sortFn = wrapColumnSortFn(wrappedFn)
    sortFn({id: '1'} as GridColumn, {id: '2'} as GridColumn)
    expect(wrappedFn).toHaveBeenCalled()
  })

  it('calls wrapped function with arguments in given order when no direction is given', () => {
    const wrappedFn = jest.fn()
    const sortFn = wrapColumnSortFn(wrappedFn)
    const first = {id: '1', field: '1'} as GridColumn
    const second = {id: '2', field: '2'} as GridColumn
    const expectedArgs = [first, second]

    sortFn(first, second)

    expect(wrappedFn).toHaveBeenCalled()
    expect(wrappedFn.mock.calls[0]).toEqual(expectedArgs)
  })

  it('calls wrapped function with arguments in given order when direction is ascending', () => {
    const wrappedFn = jest.fn()
    const sortFn = wrapColumnSortFn(wrappedFn, 'ascending')
    const first = {id: '1', field: '1'} as GridColumn
    const second = {id: '2', field: '2'} as GridColumn
    const expectedArgs = [first, second]

    sortFn(first, second)

    expect(wrappedFn).toHaveBeenCalled()
    expect(wrappedFn.mock.calls[0]).toEqual(expectedArgs)
  })

  it('calls wrapped function with arguments in reverse order when direction is descending', () => {
    const wrappedFn = jest.fn()
    const sortFn = wrapColumnSortFn(wrappedFn, 'descending')
    const first = {id: '1', field: '1'} as GridColumn
    const second = {id: '2', field: '2'} as GridColumn
    const expectedArgs = [second, first]

    sortFn(first, second)

    expect(wrappedFn).toHaveBeenCalled()
    expect(wrappedFn.mock.calls[0]).toEqual(expectedArgs)
  })
})

describe('getDefaultSettingKeyForColumnType', () => {
  it('relies on localeSort when rows have equal sorting criteria results', () => {
    const gradebook = createGradebook()
    gradebook.gridData.rows = [
      {id: '3', sortable_name: 'Z Lastington', someProperty: false},
      {id: '4', sortable_name: 'A Firstington', someProperty: true},
    ]

    const value = 0
    gradebook.gridData.rows[0].someProperty = value
    gradebook.gridData.rows[1].someProperty = value
    const sortFn = (row: GradebookStudent): number | boolean => row.someProperty
    gradebook.sortRowsWithFunction(sortFn)
    const [firstRow, secondRow] = gradebook.gridData.rows

    expect(firstRow.sortable_name).toStrictEqual('A Firstington') // 'A Firstington sorts first'
    expect(secondRow.sortable_name).toStrictEqual('Z Lastington') //  'Z Lastington sorts second'
  })
})

describe('isDefaultSortOrder', () => {
  it('returns false if called with due_date', () => {
    expect(isDefaultSortOrder('due_date')).toStrictEqual(false)
  })

  it('returns false if called with name', () => {
    expect(isDefaultSortOrder('name')).toStrictEqual(false)
  })

  it('returns false if called with points', () => {
    expect(isDefaultSortOrder('points')).toStrictEqual(false)
  })

  it('returns false if called with custom', () => {
    expect(isDefaultSortOrder('custom')).toStrictEqual(false)
  })

  it('returns false if called with module_position', () => {
    expect(isDefaultSortOrder('module_position')).toStrictEqual(false)
  })

  it('returns true if called with anything else', () => {
    expect(isDefaultSortOrder('alpha')).toStrictEqual(true)
    expect(isDefaultSortOrder('assignment_group')).toStrictEqual(true)
  })
})

describe('localeSort', () => {
  it('returns 1 if nullsLast is true and only first item is null', function () {
    expect(localeSort(null, 'fred', {nullsLast: true})).toStrictEqual(1)
  })

  it('returns -1 if nullsLast is true and only second item is null', function () {
    expect(localeSort('fred', null, {nullsLast: true})).toStrictEqual(-1)
  })
})

describe('compareAssignmentNames', () => {
  const firstRecord = {
    object: {name: 'alpha'},
  } as GridColumn
  const secondRecord = {
    object: {name: 'omega'},
  } as GridColumn
  const thirdRecord = {
    object: {name: 'Alpha'},
  } as GridColumn
  const fourthRecord = {
    object: {name: 'Omega'},
  } as GridColumn
  it('returns -1 if the name field comes first alphabetically in the first record', function () {
    expect(compareAssignmentNames(firstRecord, secondRecord)).toStrictEqual(-1)
  })

  it('returns 0 if the name field is the same in both records', function () {
    expect(compareAssignmentNames(firstRecord, firstRecord)).toStrictEqual(0)
  })

  it('returns 1 if the name field comes later alphabetically in the first record', function () {
    expect(compareAssignmentNames(secondRecord, firstRecord)).toStrictEqual(1)
  })

  it('comparison is case-sensitive between alpha and Alpha', function () {
    expect(compareAssignmentNames(thirdRecord, firstRecord)).toStrictEqual(1)
  })

  it('comparison does not group uppercase letters together', function () {
    expect(compareAssignmentNames(fourthRecord, secondRecord)).toStrictEqual(1)
  })
})
