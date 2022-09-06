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
  doesSubmissionNeedGrading,
  doFiltersMatch,
  findFilterValuesOfType,
  getAssignmentColumnId,
  getAssignmentGroupColumnId,
  getCustomColumnId,
  getDefaultSettingKeyForColumnType,
  getGradeAsPercent,
  getStudentGradeForColumn,
  onGridKeyDown,
  sectionList
} from '../Gradebook.utils'
import {isDefaultSortOrder, localeSort} from '../Gradebook.sorting'
import {createGradebook} from './GradebookSpecHelper'
import {fireEvent, screen, waitFor} from '@testing-library/dom'
import type {FilterPreset} from '../gradebook.d'
import type {Submission} from '../../../../../api.d'

const unsubmittedSubmission: Submission = {
  anonymous_id: 'dNq5T',
  assignment_id: '32',
  attempt: 1,
  cached_due_date: null,
  drop: undefined,
  entered_grade: null,
  entered_score: null,
  excused: false,
  grade: null,
  gradeLocked: false,
  grade_matches_current_submission: true,
  gradingType: 'points',
  grading_period_id: '2',
  has_postable_comments: false,
  hidden: false,
  id: '160',
  late: false,
  late_policy_status: null,
  missing: false,
  points_deducted: null,
  posted_at: null,
  rawGrade: null,
  redo_request: false,
  score: null,
  seconds_late: 0,
  submission_type: 'online_text_entry',
  submitted_at: new Date(),
  url: null,
  user_id: '28',
  workflow_state: 'unsubmitted'
}

const ungradedSubmission: Submission = {
  ...unsubmittedSubmission,
  attempt: 1,
  workflow_state: 'submitted'
}

const zeroGradedSubmission: Submission = {
  ...unsubmittedSubmission,
  attempt: 1,
  entered_grade: '0',
  entered_score: 0,
  grade: '0',
  grade_matches_current_submission: true,
  rawGrade: '0',
  score: 0,
  workflow_state: 'graded'
}

const gradedSubmission: Submission = {
  ...unsubmittedSubmission,
  attempt: 1,
  entered_grade: '5',
  entered_score: 5,
  grade: '5',
  grade_matches_current_submission: true,
  rawGrade: '5',
  score: 5,
  workflow_state: 'graded'
}

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
    const event = {which: 13, originalEvent: {skipSlickGridDefaults: undefined}}
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

    expect(firstRow.sortable_name).toStrictEqual('A Firstington')
    expect(secondRow.sortable_name).toStrictEqual('Z Lastington')
  })
})

describe('sectionList', () => {
  const sections = {
    2: {id: '2', name: 'Hello &lt;script>while(1);&lt;/script> world!'},
    1: {id: '1', name: 'Section 1'}
  }

  it('sorts by id', () => {
    const results = sectionList(sections)
    expect(results[0].id).toStrictEqual('1')
    expect(results[1].id).toStrictEqual('2')
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

describe('findConditionValuesOfType', () => {
  const filterPreset: FilterPreset[] = [
    {
      id: '1',
      name: 'Filter 1',
      filters: [
        {id: '1', type: 'module', value: '1', created_at: ''},
        {id: '2', type: 'assignment-group', value: '2', created_at: ''},
        {id: '3', type: 'assignment-group', value: '7', created_at: ''},
        {id: '4', type: 'module', value: '3', created_at: ''}
      ],
      created_at: '2019-01-01T00:00:00Z'
    },
    {
      id: '2',
      name: 'Filter 2',
      filters: [
        {id: '1', type: 'module', value: '4', created_at: ''},
        {id: '2', type: 'assignment-group', value: '5', created_at: ''},
        {id: '3', type: 'module', value: '6', created_at: ''}
      ],
      created_at: '2019-01-01T00:00:01Z'
    }
  ]

  it('returns module condition values', () => {
    expect(findFilterValuesOfType('module', filterPreset[0].filters)).toStrictEqual(['1', '3'])
  })

  it('returns assignment-group condition values', () => {
    expect(findFilterValuesOfType('assignment-group', filterPreset[1].filters)).toStrictEqual(['5'])
  })
})

describe('doFiltersMatch', () => {
  const filterPreset: FilterPreset[] = [
    {
      id: '1',
      name: 'Filter 1',
      filters: [
        {id: '1', type: 'module', value: '1', created_at: ''},
        {id: '2', type: 'assignment-group', value: '2', created_at: ''},
        {id: '3', type: 'assignment-group', value: '7', created_at: ''},
        {id: '4', type: 'module', value: '3', created_at: ''}
      ],
      created_at: '2019-01-01T00:00:00Z'
    },
    {
      id: '2',
      name: 'Filter 2',
      filters: [
        {id: '1', type: 'module', value: '4', created_at: ''},
        {id: '2', type: 'assignment-group', value: '5', created_at: ''},
        {id: '3', type: 'module', value: '6', created_at: ''}
      ],
      created_at: '2019-01-01T00:00:01Z'
    },
    {
      id: '3',
      name: 'Filter 3',
      filters: [
        {id: '1', type: 'module', value: '4', created_at: ''},
        {id: '2', type: 'assignment-group', value: '5', created_at: ''},
        {id: '3', type: 'module', value: '6', created_at: ''}
      ],
      created_at: '2019-01-01T00:00:01Z'
    }
  ]

  it('returns false if filter conditions are different', () => {
    expect(doFiltersMatch(filterPreset[0].filters, filterPreset[1].filters)).toStrictEqual(false)
  })

  it('returns true if filter conditions are the same', () => {
    expect(doFiltersMatch(filterPreset[1].filters, filterPreset[2].filters)).toStrictEqual(true)
  })
})

describe('doesSubmissionNeedGrading', () => {
  it('unsubmitted submission does not need grading', () => {
    expect(doesSubmissionNeedGrading(unsubmittedSubmission)).toStrictEqual(false)
  })

  it('submitted but ungraded submission needs grading', () => {
    expect(doesSubmissionNeedGrading(ungradedSubmission)).toStrictEqual(true)
  })

  it('zero-graded submission does not need grading', () => {
    expect(doesSubmissionNeedGrading(zeroGradedSubmission)).toStrictEqual(false)
  })

  it('none-zero graded submission does not needs grading', () => {
    expect(doesSubmissionNeedGrading(gradedSubmission)).toStrictEqual(false)
  })
})
