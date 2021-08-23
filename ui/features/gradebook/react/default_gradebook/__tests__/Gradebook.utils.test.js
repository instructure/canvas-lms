/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
  compareAssignmentPositions
} from '../Gradebook.utils'

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
    onGridKeyDown(event, {grid: this.grid, cell: undefined, row: undefined})
    // skipSlickGridDefaults is not applied
    expect('skipSlickGridDefaults' in event.originalEvent).toBeFalsy()
  })
})

describe('compareAssignmentPositions', () => {
  it('sorts (1)', () => {
    const a = {object: {position: 1, assignment_group: {position: 1}}}
    const b = {object: {position: 2, assignment_group: {position: 2}}}
    const assignments = [a, b]
    expect(assignments.sort(compareAssignmentPositions)).toStrictEqual([a, b])
  })
  it('sorts (2)', () => {
    const a = {object: {position: 1, assignment_group: {position: 2}}}
    const b = {object: {position: 2, assignment_group: {position: 1}}}
    const assignments = [a, b]
    expect(assignments.sort(compareAssignmentPositions)).toStrictEqual([b, a])
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
