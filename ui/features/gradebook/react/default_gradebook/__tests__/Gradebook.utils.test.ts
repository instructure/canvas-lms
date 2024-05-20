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
  assignmentSearchMatcher,
  confirmViewUngradedAsZero,
  doesSubmissionNeedGrading,
  doFiltersMatch,
  findFilterValuesOfType,
  filterStudentBySectionFn,
  getAssignmentColumnId,
  getAssignmentGroupColumnId,
  getCustomColumnId,
  getDefaultSettingKeyForColumnType,
  getGradeAsPercent,
  getStudentGradeForColumn,
  idArraysEqual,
  isGradedOrExcusedSubmissionUnposted,
  maxAssignmentCount,
  onGridKeyDown,
  otherGradingPeriodAssignmentIds,
  sectionList,
  getLabelForFilter,
  formatGradingPeriodTitleForDisplay,
} from '../Gradebook.utils'
import {isDefaultSortOrder, localeSort} from '../Gradebook.sorting'
import {createGradebook} from './GradebookSpecHelper'
import {fireEvent, screen, waitFor} from '@testing-library/dom'
import type {FilterPreset, Filter} from '../gradebook.d'
import type {SlickGridKeyboardEvent} from '../grid.d'
import type {Submission, Student, Enrollment, GradingPeriod} from '../../../../../api.d'
import {enrollment, student, enrollmentFilter, appliedFilters, student2} from './fixtures'

const unsubmittedSubmission: Submission = {
  anonymous_id: 'dNq5T',
  assignment_id: '32',
  attempt: 1,
  cached_due_date: null,
  custom_grade_status_id: null,
  drop: undefined,
  entered_grade: null,
  entered_score: null,
  excused: false,
  grade_matches_current_submission: true,
  grade: null,
  graded_at: null,
  gradeLocked: false,
  grading_period_id: '2',
  grading_type: 'points',
  gradingType: 'points',
  has_originality_report: false,
  has_postable_comments: false,
  hidden: false,
  id: '160',
  late_policy_status: null,
  late: false,
  missing: false,
  points_deducted: null,
  posted_at: null,
  provisional_grade_id: '3',
  rawGrade: null,
  redo_request: false,
  score: null,
  seconds_late: 0,
  similarityInfo: null,
  submission_comments: [],
  submission_type: 'online_text_entry',
  submitted_at: new Date(),
  url: null,
  user_id: '28',
  word_count: null,
  workflow_state: 'unsubmitted',
  updated_at: new Date().toString(),
}

const ungradedSubmission: Submission = {
  ...unsubmittedSubmission,
  attempt: 1,
  workflow_state: 'submitted',
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
  workflow_state: 'graded',
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
  workflow_state: 'graded',
}

const gradedPostedSubmission: Submission = {
  ...gradedSubmission,
  posted_at: new Date(),
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

describe('idArraysEqual', () => {
  it('returns true when passed two sets of ids with the same contents', () => {
    expect(idArraysEqual(['1', '2'], ['1', '2'])).toStrictEqual(true)
  })

  it('returns true when passed two sets of ids with the same contents in different order', () => {
    expect(idArraysEqual(['2', '1'], ['1', '2'])).toStrictEqual(true)
  })

  it('returns true when passed two empty arrays', () => {
    expect(idArraysEqual([], [])).toStrictEqual(true)
  })

  it('returns false when passed two different sets of ids', () => {
    expect(idArraysEqual(['1'], ['1', '2'])).toStrictEqual(false)
  })
})

describe('onGridKeyDown', () => {
  let grid: any
  let columns: any

  beforeEach(() => {
    columns = [
      {id: 'student', type: 'student'},
      {id: 'assignment_2301', type: 'assignment'},
    ]
    grid = {
      getColumns() {
        return columns
      },
    }
  })

  it('skips SlickGrid default behavior when pressing "enter" on a "student" cell', () => {
    const event = {
      which: 13,
      originalEvent: {skipSlickGridDefaults: undefined},
    } as any
    onGridKeyDown(event, {grid, cell: 0, row: 0}) // 0 is the index of the 'student' column
    expect(event.originalEvent.skipSlickGridDefaults).toStrictEqual(true)
  })

  it('does not skip SlickGrid default behavior when pressing other keys on a "student" cell', function () {
    const event = {which: 27, originalEvent: {}} as SlickGridKeyboardEvent
    onGridKeyDown(event, {grid, cell: 0, row: 0}) // 0 is the index of the 'student' column
    // skipSlickGridDefaults is not applied
    expect('skipSlickGridDefaults' in event.originalEvent).toBeFalsy()
  })

  it('does not skip SlickGrid default behavior when pressing "enter" on other cells', function () {
    const event = {which: 27, originalEvent: {}} as SlickGridKeyboardEvent
    onGridKeyDown(event, {grid, cell: 1, row: 0}) // 1 is the index of the 'assignment' column
    // skipSlickGridDefaults is not applied
    expect('skipSlickGridDefaults' in event.originalEvent).toBeFalsy()
  })

  it('does not skip SlickGrid default behavior when pressing "enter" off the grid', function () {
    const event = {which: 27, originalEvent: {}} as SlickGridKeyboardEvent
    onGridKeyDown(event, {grid, cell: null, row: null})
    // skipSlickGridDefaults is not applied
    expect('skipSlickGridDefaults' in event.originalEvent).toBeFalsy()
  })
})

describe('confirmViewUngradedAsZero', () => {
  let onAccepted: () => void

  const confirm = (currentValue: boolean) => {
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
      {id: '4', sortable_name: 'A Firstington', someProperty: true},
    ]

    const value = 0
    gradebook.gridData.rows[0].someProperty = value
    gradebook.gridData.rows[1].someProperty = value
    const sortFn = (row: any) => row.someProperty
    gradebook.sortRowsWithFunction(sortFn)
    const [firstRow, secondRow] = gradebook.gridData.rows

    expect(firstRow.sortable_name).toStrictEqual('A Firstington')
    expect(secondRow.sortable_name).toStrictEqual('Z Lastington')
  })
})

describe('sectionList', () => {
  const sections = {
    2: {
      id: '2',
      name: 'Hello &lt;script>while(1);&lt;/script> world!',
    },
    1: {id: '1', name: 'Section 1', course_id: '1'},
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
        {id: '4', type: 'module', value: '3', created_at: ''},
      ],
      created_at: '2019-01-01T00:00:00Z',
      updated_at: '2019-01-01T00:00:00Z',
    },
    {
      id: '2',
      name: 'Filter 2',
      filters: [
        {id: '1', type: 'module', value: '4', created_at: ''},
        {id: '2', type: 'assignment-group', value: '5', created_at: ''},
        {id: '3', type: 'module', value: '6', created_at: ''},
      ],
      created_at: '2019-01-01T00:00:01Z',
      updated_at: '2019-01-01T00:00:00Z',
    },
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
        {id: '4', type: 'module', value: '3', created_at: ''},
      ],
      created_at: '2019-01-01T00:00:00Z',
      updated_at: '2019-01-01T00:00:00Z',
    },
    {
      id: '2',
      name: 'Filter 2',
      filters: [
        {id: '1', type: 'module', value: '4', created_at: ''},
        {id: '2', type: 'assignment-group', value: '5', created_at: ''},
        {id: '3', type: 'module', value: '6', created_at: ''},
      ],
      created_at: '2019-01-01T00:00:01Z',
      updated_at: '2019-01-01T00:00:00Z',
    },
    {
      id: '3',
      name: 'Filter 3',
      filters: [
        {id: '1', type: 'module', value: '4', created_at: ''},
        {id: '2', type: 'assignment-group', value: '5', created_at: ''},
        {id: '3', type: 'module', value: '6', created_at: ''},
      ],
      created_at: '2019-01-01T00:00:01Z',
      updated_at: '2019-01-01T00:00:00Z',
    },
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

describe('assignmentSearchMatcher', () => {
  it('returns true if the search term is a substring of the assignment name (case insensitive)', () => {
    const option = {id: '122', label: 'Science Lab II'}
    expect(assignmentSearchMatcher(option, 'lab')).toStrictEqual(true)
  })

  test('returns false if the search term is not a substring of the assignment name', () => {
    const option = {id: '122', label: 'Science Lab II'}
    expect(assignmentSearchMatcher(option, 'Lib')).toStrictEqual(false)
  })

  test('does not treat the search term as a regular expression', () => {
    const option = {id: '122', label: 'Science Lab II'}
    expect(assignmentSearchMatcher(option, 'Science.*II')).toStrictEqual(false)
  })
})

describe('maxAssignmentCount', () => {
  it('computes max number of assignments that can be made in a request', () => {
    expect(
      maxAssignmentCount(
        {
          include: ['a', 'b'],
          override_assignment_dates: true,
          exclude_response_fields: ['c', 'd'],
          exclude_assignment_submission_types: ['on_paper', 'discussion_topic'],
          per_page: 10,
          assignment_ids: '1,2,3',
        },
        'courses/1/long/1/url'
      )
    ).toStrictEqual(698)
  })
})

describe('otherGradingPeriodAssignmentIds', () => {
  it('computes max number of assignments that can be made in a request', () => {
    const gradingPeriodAssignments = {
      1: ['1', '2', '3', '4', '5'],
      2: ['6', '7', '8', '9', '10'],
    }
    const selectedAssignmentIds = ['1', '2']
    const selectedPeriodId = '1'
    expect(
      otherGradingPeriodAssignmentIds(
        gradingPeriodAssignments,
        selectedAssignmentIds,
        selectedPeriodId
      )
    ).toStrictEqual({
      otherGradingPeriodIds: ['2'],
      otherAssignmentIds: ['3', '4', '5', '6', '7', '8', '9', '10'],
    })
  })
})

describe('isGradedOrExcusedSubmissionUnposted', () => {
  it('returns true if submission is graded or excused but not posted', () => {
    expect(isGradedOrExcusedSubmissionUnposted(gradedSubmission)).toStrictEqual(true)
  })

  it('returns false if submission is graded or excused and posted', () => {
    expect(isGradedOrExcusedSubmissionUnposted(gradedPostedSubmission)).toStrictEqual(false)
  })

  it('returns false if submission is ungraded', () => {
    expect(isGradedOrExcusedSubmissionUnposted(ungradedSubmission)).toStrictEqual(false)
  })
})

describe('filterStudentBySectionFn', () => {
  describe('section filtering', () => {
    let modifiedStudents: Student[]
    const enrollmentFilterTest = {...enrollmentFilter}
    const appliedFilterTest = [...appliedFilters]
    beforeEach(() => {
      const enrollment1: Enrollment = {
        ...enrollment,
        course_section_id: 'section1',
        enrollment_state: 'active',
      }
      const enrollment2: Enrollment = {
        ...enrollment,
        course_section_id: 'section1',
        enrollment_state: 'active',
      }
      const enrollment3: Enrollment = {
        ...enrollment,
        course_section_id: 'section2',
        enrollment_state: 'active',
      }
      const modifiedStudent1: Student = {...student, name: 'Jim Doe', enrollments: [enrollment1]}
      const modifiedStudent2: Student = {
        ...student,
        name: 'Bob Jim',
        enrollments: [enrollment2, enrollment3],
      }
      modifiedStudents = [modifiedStudent1, modifiedStudent2]
    })
    it('students appear in the correct sections when switching between filters', () => {
      appliedFilterTest[0].value = 'section1'
      const filteredStudentsSection1 = modifiedStudents.filter(
        filterStudentBySectionFn(appliedFilters, enrollmentFilterTest)
      )
      expect(filteredStudentsSection1.length).toBe(2)
      appliedFilterTest[0].value = 'section2'
      const filteredStudentsSection2 = modifiedStudents.filter(
        filterStudentBySectionFn(appliedFilters, enrollmentFilterTest)
      )
      expect(filteredStudentsSection2[0].name).toBe('Bob Jim')
    })
  })

  describe('enrollment filters', () => {
    let modifiedStudents: Student[]
    const enrollmentFilterTest = {...enrollmentFilter}
    const appliedFilterTest = [...appliedFilters]
    beforeEach(() => {
      const enrollment1: Enrollment = {
        ...enrollment,
        course_section_id: 'section1',
        enrollment_state: 'completed',
      }
      const enrollment2: Enrollment = {
        ...enrollment,
        course_section_id: 'section1',
        enrollment_state: 'inactive',
      }
      const modifiedStudent1: Student = {...student, name: 'Jim Doe', enrollments: [enrollment1]}
      const modifiedStudent2: Student = {...student, name: 'Bob Jim', enrollments: [enrollment2]}
      modifiedStudents = [modifiedStudent1, modifiedStudent2]
    })
    it('student appears in section 1 with a completed enrollment when the concluded enrollment filter is on ', () => {
      enrollmentFilterTest.concluded = true
      appliedFilterTest[0].value = 'section1'
      const filteredStudentsSection1 = modifiedStudents.filter(
        filterStudentBySectionFn(appliedFilters, enrollmentFilterTest)
      )
      expect(filteredStudentsSection1.length).toBe(1)
      expect(filteredStudentsSection1[0].name).toBe('Jim Doe')
    })
    it('student appears in section 1 with a inactive enrollment when the inactive enrollment filter is on ', () => {
      enrollmentFilterTest.inactive = true
      enrollmentFilterTest.concluded = false
      appliedFilterTest[0].value = 'section1'
      const filteredStudentsSection1 = modifiedStudents.filter(
        filterStudentBySectionFn(appliedFilters, enrollmentFilterTest)
      )
      expect(filteredStudentsSection1.length).toBe(1)
      expect(filteredStudentsSection1[0].name).toBe('Bob Jim')
    })
    it('both students appear in section 1 when concluded and inactive enrollment filters are both on ', () => {
      enrollmentFilterTest.inactive = true
      enrollmentFilterTest.concluded = true
      appliedFilterTest[0].value = 'section1'
      const filteredStudentsSection1 = modifiedStudents.filter(
        filterStudentBySectionFn(appliedFilters, enrollmentFilterTest)
      )
      expect(filteredStudentsSection1.length).toBe(2)
    })
  })

  describe('dual enrollment', () => {
    const enrollmentFilterTest = {...enrollmentFilter}
    const appliedFilterTest = [...appliedFilters]
    let modifiedStudents: Student[]
    const enrollment3: Enrollment = {
      ...enrollment,
      course_section_id: 'section2',
      enrollment_state: 'active',
    }
    const modifiedStudent2: Student = {...student2, enrollments: [enrollment3]}
    beforeEach(() => {
      const enrollment1: Enrollment = {
        ...enrollment,
        course_section_id: 'section1',
        enrollment_state: 'active',
      }
      const enrollment2: Enrollment = {
        ...enrollment,
        course_section_id: 'section2',
        enrollment_state: 'completed',
      }
      const modifiedStudent: Student = {...student, enrollments: [enrollment1, enrollment2]}
      modifiedStudents = [modifiedStudent]
    })
    it('dual enrollment student appears in section 1 with an active enrollment ', () => {
      appliedFilterTest[0].value = 'section1'
      const filteredStudentsSection1 = modifiedStudents.filter(
        filterStudentBySectionFn(appliedFilterTest, enrollmentFilterTest)
      )
      expect(filteredStudentsSection1[0].name).toBe('Jim Doe')
    })

    it('dual enrollment student does not appear section 2 with a concluded enrollment ', () => {
      appliedFilterTest[0].value = 'section2'
      const filteredStudentsSection2 = modifiedStudents.filter(
        filterStudentBySectionFn(appliedFilterTest, enrollmentFilterTest)
      )
      expect(filteredStudentsSection2.length).toBe(0)
    })

    it('dual enrollment student appears in section 2 with a concluded enrollment when the concluded enrollment filter is on ', () => {
      enrollmentFilterTest.concluded = true
      appliedFilterTest[0].value = 'section2'
      const filteredStudentsSection2 = modifiedStudents.filter(
        filterStudentBySectionFn(appliedFilterTest, enrollmentFilterTest)
      )
      expect(filteredStudentsSection2[0].name).toBe('Jim Doe')
    })

    it('filteredStudents include all students when appliedFilters includes multiple sections when multiselect_gradebook_filters_enabled is true', () => {
      modifiedStudents.push(modifiedStudent2)
      ENV.GRADEBOOK_OPTIONS = {multiselect_gradebook_filters_enabled: true}
      const appliedFilters: Filter[] = [
        {
          id: '1',
          type: 'section',
          created_at: '',
          value: 'section1',
        },
        {
          id: '1',
          type: 'section',
          created_at: '',
          value: 'section2',
        },
      ]
      const filteredStudents = modifiedStudents.filter(
        filterStudentBySectionFn(appliedFilters, enrollmentFilterTest)
      )
      expect(filteredStudents.length).toBe(2)
    })

    it('filteredStudents does not include all students when appliedFilters includes multiple sections when multiselect_gradebook_filters_enabled is false', () => {
      modifiedStudents.push(modifiedStudent2)
      ENV.GRADEBOOK_OPTIONS = {multiselect_gradebook_filters_enabled: false}
      const appliedFilters: Filter[] = [
        {
          id: '1',
          type: 'section',
          created_at: '',
          value: 'section1',
        },
        {
          id: '1',
          type: 'section',
          created_at: '',
          value: 'section2',
        },
      ]
      const filteredStudents = modifiedStudents.filter(
        filterStudentBySectionFn(appliedFilters, enrollmentFilterTest)
      )
      expect(filteredStudents.length).toBe(1)
    })
  })

  describe('filter start and end date pill display', () => {
    ENV.TIMEZONE = 'Asia/Tokyo'

    const startFilter: Filter = {
      id: '1',
      type: 'start-date',
      created_at: '',
      value: '2023-12-13T16:00:00.000Z',
    }

    const endFilter: Filter = {
      id: '1',
      type: 'end-date',
      created_at: '',
      value: '2023-12-15T16:00:00.000Z',
    }

    it('takes the UTC filter start-date and converts it to user local time for filter pill display', () => {
      const result = getLabelForFilter(startFilter, [], [], [], [], {}, [])
      expect(result).toEqual('Start Date 12/14/2023')
    })

    it('takes the UTC filter end-date and converts it to user local time for filter pill display', () => {
      const result = getLabelForFilter(endFilter, [], [], [], [], {}, [])
      expect(result).toEqual('End Date 12/16/2023')
    })
  })
})

describe('formatGradingPeriodTitleForDisplay', () => {
  ENV.GRADEBOOK_OPTIONS = {grading_periods_filter_dates_enabled: true}
  const gp: GradingPeriod = {
    id: '1',
    title: 'GP1',
    startDate: new Date('2021-01-01'),
    endDate: new Date('2021-01-31'),
    closeDate: new Date('2021-02-01'),
  }

  it('returns null if handed a null grading period', () => {
    const result = formatGradingPeriodTitleForDisplay(null)
    expect(result).toBeNull()
  })

  it('returns null if handed an undefined grading period', () => {
    const result = formatGradingPeriodTitleForDisplay(undefined)
    expect(result).toBeNull()
  })

  // TODO: remove "with the feature flag" from the test description when the feature flag is removed
  it('returns the grading period title with the start, end, and close dates with the feature flag', () => {
    ENV.GRADEBOOK_OPTIONS = {grading_periods_filter_dates_enabled: true}
    const result = formatGradingPeriodTitleForDisplay(gp)
    expect(result).toEqual('GP1: 1/1/21 - 1/31/21 | 2/1/21')
  })

  // TODO: remove this test when we remove the feature flag
  it('returns only the grading period title without the feature flag', () => {
    ENV.GRADEBOOK_OPTIONS = {grading_periods_filter_dates_enabled: false}
    const result = formatGradingPeriodTitleForDisplay(gp)
    expect(result).toEqual('GP1')
  })
})
