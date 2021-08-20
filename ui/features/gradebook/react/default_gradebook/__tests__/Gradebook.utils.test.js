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

import {
  confirmViewUngradedAsZero,
  getStudentGradeForColumn,
  getGradeAsPercent,
  onGridKeyDown,
  getDefaultSettingKeyForColumnType,
  sectionList,
  getCustomColumnId,
  getAssignmentColumnId,
  getAssignmentGroupColumnId
} from '../Gradebook.utils'
import {isDefaultSortOrder, localeSort} from '../Gradebook.sorting'
import {createGradebook} from './GradebookSpecHelper'
import {fireEvent, screen, waitFor} from '@testing-library/dom'

describe('getGradeAsPercent', () => {
  it('returns a percent for a grade with points possible', () => {
    const percent = getGradeAsPercent({score: 5, possible: 10})
    expect(percent).toStrictEqual(0.5)
  })

  it('returns null for a grade with no points possible', () => {
    const percent = getGradeAsPercent({score: 5, possible: 0})
    expect(percent).toStrictEqual(null)
  })

  it('returns 0 for a grade with a null score', () => {
    const percent = getGradeAsPercent({score: null, possible: 10})
    expect(percent).toStrictEqual(0)
  })

  it('returns 0 for a grade with an undefined score', () => {
    const percent = getGradeAsPercent({score: undefined, possible: 10})
    expect(percent).toStrictEqual(0)
  })
})

describe('getStudentGradeForColumn', () => {
  it('returns the grade stored on the student for the column id', () => {
    const student = {total_grade: {score: 5, possible: 10}}
    const grade = getStudentGradeForColumn(student, 'total_grade')
    expect(grade).toEqual(student.total_grade)
  })

  it('returns an empty grade when the student has no grade for the column id', () => {
    const student = {total_grade: undefined}
    const grade = getStudentGradeForColumn(student, 'total_grade')
    expect(grade.score).toStrictEqual(null)
    expect(grade.possible).toStrictEqual(0)
  })
})

describe('onGridKeyDown', () => {
  let grid
  let columns

  beforeEach(() => {
    columns = [
      {id: 'student', type: 'student'},
      {id: 'assignment_2301', type: 'assignment'}
    ]
    grid = {
      getColumns() {
        return columns
      }
    }
  })

  it('skips SlickGrid default behavior when pressing "enter" on a "student" cell', () => {
    const event = {which: 13, originalEvent: {}}
    onGridKeyDown(event, {grid, cell: 0, row: 0}) // 0 is the index of the 'student' column
    expect(event.originalEvent.skipSlickGridDefaults).toStrictEqual(true)
  })

  it('does not skip SlickGrid default behavior when pressing other keys on a "student" cell', function () {
    const event = {which: 27, originalEvent: {}}
    onGridKeyDown(event, {grid, cell: 0, row: 0}) // 0 is the index of the 'student' column
    // skipSlickGridDefaults is not applied
    expect('skipSlickGridDefaults' in event.originalEvent).toBeFalsy()
  })

  it('does not skip SlickGrid default behavior when pressing "enter" on other cells', function () {
    const event = {which: 27, originalEvent: {}}
    onGridKeyDown(event, {grid, cell: 1, row: 0}) // 1 is the index of the 'assignment' column
    // skipSlickGridDefaults is not applied
    expect('skipSlickGridDefaults' in event.originalEvent).toBeFalsy()
  })

  it('does not skip SlickGrid default behavior when pressing "enter" off the grid', function () {
    const event = {which: 27, originalEvent: {}}
    onGridKeyDown(event, {grid, cell: undefined, row: undefined})
    // skipSlickGridDefaults is not applied
    expect('skipSlickGridDefaults' in event.originalEvent).toBeFalsy()
  })
})

describe('confirmViewUngradedAsZero', () => {
  let onAccepted

  const confirm = currentValue => {
    document.body.innerHTML = '<div id="confirmation_dialog_holder" />'
    confirmViewUngradedAsZero({currentValue, onAccepted})
  }

  beforeEach(() => {
    onAccepted = jest.fn()
  })

  describe('when initialValue is false', () => {
    it('shows a confirmation dialog', () => {
      confirm(false)
      expect(
        screen.getByText(/This setting only affects your view of student grades/)
      ).toBeInTheDocument()
    })

    it('calls the onAccepted prop if the user accepts the confirmation', async () => {
      confirm(false)
      const confirmButton = await waitFor(() => screen.getByRole('button', {name: /OK/}))
      fireEvent.click(confirmButton)
      await waitFor(() => {
        expect(onAccepted).toHaveBeenCalled()
      })
    })

    it('does not call the onAccepted prop if the user does not accept the confirmation', async () => {
      confirm(false)
      const cancelButton = await waitFor(() => screen.getByRole('button', {name: /Cancel/}))
      fireEvent.click(cancelButton)
      expect(onAccepted).not.toHaveBeenCalled()
    })
  })

  describe('when initialValue is true', () => {
    it('calls the onAccepted prop immediately', () => {
      confirm(true)
      expect(onAccepted).toHaveBeenCalled()
    })
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

describe('getDefaultSettingKeyForColumnType', () => {
  it('returns grade for assignment', function () {
    expect(getDefaultSettingKeyForColumnType('assignment')).toStrictEqual('grade')
  })

  it('returns grade for assignment_group', function () {
    expect(getDefaultSettingKeyForColumnType('assignment_group')).toStrictEqual('grade')
  })

  it('returns grade for total_grade', function () {
    expect(getDefaultSettingKeyForColumnType('total_grade')).toStrictEqual('grade')
  })

  it('returns sortable_name for student', function () {
    expect(getDefaultSettingKeyForColumnType('student')).toStrictEqual('sortable_name')
  })

  it('relies on localeSort when rows have equal sorting criteria results', () => {
    const gradebook = createGradebook()
    gradebook.gridData.rows = [
      {id: '3', sortable_name: 'Z Lastington', someProperty: false},
      {id: '4', sortable_name: 'A Firstington', someProperty: true}
    ]

    const value = 0
    gradebook.gridData.rows[0].someProperty = value
    gradebook.gridData.rows[1].someProperty = value
    const sortFn = row => row.someProperty
    gradebook.sortRowsWithFunction(sortFn)
    const [firstRow, secondRow] = gradebook.gridData.rows

    expect(firstRow.sortable_name).toStrictEqual('A Firstington', 'A Firstington sorts first')
    expect(secondRow.sortable_name).toStrictEqual('Z Lastington', 'Z Lastington sorts second')
  })
})

describe('sectionList', () => {
  const sections = {
    2: {id: 2, name: 'Hello &lt;script>while(1);&lt;/script> world!'},
    1: {id: 1, name: 'Section 1'}
  }

  it('sorts by id', () => {
    const results = sectionList(sections)
    expect(results[0].id).toStrictEqual(1)
    expect(results[1].id).toStrictEqual(2)
  })

  it('unescapes section names', () => {
    const results = sectionList(sections)
    expect(results[1].name).toStrictEqual('Hello <script>while(1);</script> world!')
  })
})

describe('getCustomColumnId', () => {
  it('returns a unique key for the custom column', () => {
    expect(getCustomColumnId('2401')).toStrictEqual('custom_col_2401')
  })
})

describe('getAssignmentColumnId', () => {
  it('returns a unique key for the assignment column', () => {
    expect(getAssignmentColumnId('201')).toStrictEqual('assignment_201')
  })
})

describe('getAssignmentGroupColumnId', () => {
  it('returns a unique key for the assignment column', () => {
    expect(getAssignmentGroupColumnId('301')).toStrictEqual('assignment_group_301')
  })
})
