/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {createGradebook} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'

QUnit.module('Gradebook#setAssignmentsLoaded', hooks => {
  let gradebook

  hooks.beforeEach(() => {
    gradebook = createGradebook()
    gradebook.contentLoadStates.assignmentsLoaded.gradingPeriod = {2: false, 59: false}
  })

  test('sets all assignments as loaded', () => {
    gradebook.setAssignmentsLoaded()
    strictEqual(gradebook.contentLoadStates.assignmentsLoaded.all, true)
  })

  test('sets all grading periods as loaded', () => {
    gradebook.setAssignmentsLoaded()
    const gpLoadStates = Object.values(gradebook.contentLoadStates.assignmentsLoaded.gradingPeriod)
    strictEqual(
      gpLoadStates.every(loaded => loaded),
      true
    )
  })

  QUnit.module('when assignments are loaded for particular grading periods', () => {
    test('sets assignments loaded for the expected grading period', () => {
      gradebook.setAssignmentsLoaded(['59'])
      strictEqual(gradebook.contentLoadStates.assignmentsLoaded.gradingPeriod[59], true)
    })

    test('does not set assignments loaded for excluded grading periods', () => {
      gradebook.setAssignmentsLoaded(['59'])
      strictEqual(gradebook.contentLoadStates.assignmentsLoaded.gradingPeriod[2], false)
    })

    test('sets all assignments loaded if all grading periods are loaded', () => {
      gradebook.setAssignmentsLoaded(['59', '2'])
      strictEqual(gradebook.contentLoadStates.assignmentsLoaded.all, true)
    })

    test('does not set all assignments loaded if not all grading periods are loaded', () => {
      gradebook.setAssignmentsLoaded(['59'])
      strictEqual(gradebook.contentLoadStates.assignmentsLoaded.all, false)
    })
  })
})

QUnit.module('Gradebook#getSubmission', hooks => {
  let gradebook

  hooks.beforeEach(() => {
    gradebook = createGradebook()
    gradebook.students = {
      1101: {id: '1101', assignment_201: {score: 10, possible: 20}, assignment_202: {}},
      1102: {id: '1102', assignment_201: {}},
    }
  })

  test('returns the submission when the student and submission are both present', () => {
    deepEqual(gradebook.getSubmission('1101', '201'), {score: 10, possible: 20})
  })

  test('returns undefined when the student is present but the submission is not', () => {
    strictEqual(gradebook.getSubmission('1101', '999'), undefined)
  })

  test('returns undefined when the student is not present', () => {
    strictEqual(gradebook.getSubmission('2202', '201'), undefined)
  })
})

QUnit.module('Gradebook#gotAllAssignmentGroups', hooks => {
  let gradebook

  hooks.beforeEach(() => {
    gradebook = createGradebook()
  })

  test('sets the "assignment groups loaded" state', () => {
    sinon.stub(gradebook, 'setAssignmentGroupsLoaded')
    gradebook.gotAllAssignmentGroups([])
    strictEqual(gradebook.setAssignmentGroupsLoaded.callCount, 1)
  })

  test('sets the "assignment groups loaded" state to true', () => {
    sinon.stub(gradebook, 'setAssignmentGroupsLoaded')
    gradebook.gotAllAssignmentGroups([])
    strictEqual(gradebook.setAssignmentGroupsLoaded.getCall(0).args[0], true)
  })

  test('adds the assignment group to the group definitions if it is new', () => {
    sinon.stub(gradebook, 'setAssignmentGroupsLoaded')
    const assignmentGroup = {
      id: '12',
      assignments: [{id: '35', name: 'An Assignment', due_at: null}],
    }
    gradebook.gotAllAssignmentGroups([assignmentGroup])
    deepEqual(gradebook.assignmentGroups['12'], assignmentGroup)
  })

  test('adds new assignments to existing assignment groups', () => {
    sinon.stub(gradebook, 'setAssignmentGroupsLoaded')
    gradebook.assignmentGroups['12'] = {
      id: '12',
      assignments: [{id: '22', name: 'Some Other Assignment', due_at: null}],
    }
    const assignmentGroup = {
      id: '12',
      assignments: [{id: '35', name: 'An Assignment', due_at: null}],
    }
    gradebook.gotAllAssignmentGroups([assignmentGroup])
    const assignmentIds = gradebook.assignmentGroups['12'].assignments.map(a => a.id)
    deepEqual(assignmentIds, ['22', '35'])
  })

  test('does not add duplicate assignments to assignment groups', () => {
    sinon.stub(gradebook, 'setAssignmentGroupsLoaded')
    gradebook.assignmentGroups['12'] = {
      id: '12',
      assignments: [{id: '35', name: 'An Assignment', due_at: null}],
    }
    const assignmentGroup = {
      id: '12',
      assignments: [{id: '35', name: 'An Assignment', due_at: null}],
    }
    gradebook.gotAllAssignmentGroups([assignmentGroup])
    const assignmentIds = gradebook.assignmentGroups['12'].assignments.map(a => a.id)
    deepEqual(assignmentIds, ['35'])
  })
})

QUnit.module('Gradebook#gotGradingPeriodAssignments', () => {
  test('sets the grading period assignments', () => {
    const gradebook = createGradebook()
    const gradingPeriodAssignments = {1: [12, 7, 4], 8: [6, 2, 9]}
    const fakeResponse = {grading_period_assignments: gradingPeriodAssignments}
    gradebook.gotGradingPeriodAssignments(fakeResponse)
    strictEqual(gradebook.courseContent.gradingPeriodAssignments, gradingPeriodAssignments)
  })
})

QUnit.module('Gradebook#updateStudentHeadersAndReloadData', hooks => {
  let gradebook

  hooks.beforeEach(() => {
    gradebook = createGradebook()
  })

  test('makes a call to update column headers', () => {
    const updateColumnHeaders = sinon.stub(
      gradebook.gradebookGrid.gridSupport.columns,
      'updateColumnHeaders'
    )
    gradebook.updateStudentHeadersAndReloadData()
    strictEqual(updateColumnHeaders.callCount, 1)
  })

  test('updates the student column header', () => {
    const updateColumnHeaders = sinon.stub(
      gradebook.gradebookGrid.gridSupport.columns,
      'updateColumnHeaders'
    )
    gradebook.updateStudentHeadersAndReloadData()
    const [columnHeadersToUpdate] = updateColumnHeaders.lastCall.args
    deepEqual(columnHeadersToUpdate, ['student'])
  })
})

QUnit.module('Gradebook#gotCustomColumnDataChunk', {
  setup() {
    this.gradebook = createGradebook()
    this.gradebook.students = {
      1101: {id: '1101', assignment_201: {}, assignment_202: {}},
      1102: {id: '1102', assignment_201: {}},
    }
    sandbox.stub(this.gradebook, 'invalidateRowsForStudentIds')
  },
})

test('updates students with custom column data', function () {
  const data = [
    {user_id: '1101', content: 'example'},
    {user_id: '1102', content: 'sample'},
  ]
  this.gradebook.gotCustomColumnDataChunk('2401', data)
  equal(this.gradebook.students[1101].custom_col_2401, 'example')
  equal(this.gradebook.students[1102].custom_col_2401, 'sample')
})

test('invalidates rows for related students', function () {
  const data = [
    {user_id: '1101', content: 'example'},
    {user_id: '1102', content: 'sample'},
  ]
  this.gradebook.gotCustomColumnDataChunk('2401', data)
  strictEqual(this.gradebook.invalidateRowsForStudentIds.callCount, 1)
  const [studentIds] = this.gradebook.invalidateRowsForStudentIds.lastCall.args
  deepEqual(studentIds, ['1101', '1102'], 'both students had custom column data')
})

test('ignores students without custom column data', function () {
  const data = [{user_id: '1102', content: 'sample'}]
  this.gradebook.gotCustomColumnDataChunk('2401', data)
  const [studentIds] = this.gradebook.invalidateRowsForStudentIds.lastCall.args
  deepEqual(studentIds, ['1102'], 'only the student 1102 had custom column data')
})

test('invalidates rows after updating students', function () {
  const data = [
    {user_id: '1101', content: 'example'},
    {user_id: '1102', content: 'sample'},
  ]
  this.gradebook.invalidateRowsForStudentIds.callsFake(() => {
    equal(this.gradebook.students[1101].custom_col_2401, 'example')
    equal(this.gradebook.students[1102].custom_col_2401, 'sample')
  })
  this.gradebook.gotCustomColumnDataChunk('2401', data)
})

QUnit.module('Gradebook#getStudentOrder', () => {
  test('returns the IDs of the ordered students in Gradebook', () => {
    const gradebook = createGradebook()
    gradebook.gridData.rows = [
      {id: '3', sortable_name: 'Z'},
      {id: '4', sortable_name: 'A'},
      {id: '1', sortable_name: 'C'},
    ]
    propEqual(gradebook.getStudentOrder(), ['3', '4', '1'])
  })
})

QUnit.module('Gradebook#getAssignmentOrder', hooks => {
  let gradebook

  hooks.beforeEach(() => {
    gradebook = createGradebook()
    gradebook.gridData.columns.scrollable = [
      'assignment_2301',
      'assignment_2302',
      'assignment_2303',
      'assignment_2304',
      'Assignments',
      'Homework',
      'total_grade',
    ]

    const assignments = [
      {
        id: '2301',
        assignment_group_id: '2201',
      },
      {
        id: '2302',
        assignment_group_id: '2201',
      },
      {
        id: '2303',
        assignment_group_id: '2202',
      },
      {
        id: '2304',
        assignment_group_id: '2202',
      },
    ]

    gradebook.gotAllAssignmentGroups([
      {id: '2201', position: 1, name: 'Assignments', assignments: assignments.slice(0, 2)},
      {id: '2202', position: 2, name: 'Homework', assignments: assignments.slice(2, 4)},
    ])
  })

  test('returns the IDs of the assignments in the assignment group', () => {
    deepEqual(gradebook.getAssignmentOrder('2201'), ['2301', '2302'])
  })

  test('returns the IDs of the all assignments if no assignment group id is specified', () => {
    deepEqual(gradebook.getAssignmentOrder(), ['2301', '2302', '2303', '2304'])
  })
})

QUnit.module('Gradebook#getGradingPeriodAssignments', hooks => {
  let gradebook

  hooks.beforeEach(() => {
    gradebook = createGradebook()
    gradebook.gotGradingPeriodAssignments({grading_period_assignments: {14: ['3', '92', '11']}})
  })

  test('returns the assignments for the given grading period', () => {
    deepEqual(gradebook.getGradingPeriodAssignments(14), ['3', '92', '11'])
  })

  test('returns an empty array if there are no assignments in the given period', () => {
    deepEqual(gradebook.getGradingPeriodAssignments(23), [])
  })
})

QUnit.module('Gradebook Assignment Student Visibility', moduleHooks => {
  let gradebook
  let allStudents
  let assignments

  moduleHooks.beforeEach(() => {
    gradebook = createGradebook()

    allStudents = [
      {
        id: '1101',
        name: 'A`dam Jone`s',
        first_name: 'A`dam',
        last_name: 'Jone`s',
        enrollments: [{type: 'StudentEnrollment', grades: {html_url: 'http://example.url/'}}],
        sortable_name: 'Jone`s, A`dam',
      },
      {
        id: '1102',
        name: 'Betty Ford',
        enrollments: [{type: 'StudentEnrollment', grades: {html_url: 'http://example.url/'}}],
      },
    ]

    assignments = [
      {
        id: '2301',
        assignment_visibility: null,
        only_visible_to_overrides: false,
      },
      {
        id: '2302',
        assignment_visibility: ['1102'],
        only_visible_to_overrides: true,
      },
    ]

    gradebook.gotAllAssignmentGroups([
      {id: '2201', position: 1, name: 'Assignments', assignments: assignments.slice(0, 1)},
      {id: '2202', position: 2, name: 'Homework', assignments: assignments.slice(1, 2)},
    ])
  })

  QUnit.module('#studentsThatCanSeeAssignment', hooks => {
    let saveSettingsStub

    hooks.beforeEach(() => {
      saveSettingsStub = sinon
        .stub(gradebook, 'saveSettings')
        .callsFake((_context_id, gradebook_settings) => Promise.resolve(gradebook_settings))
    })

    hooks.afterEach(() => {
      saveSettingsStub.restore()
    })

    test('does not escape the grades URL for students', () => {
      gradebook.gotChunkOfStudents(allStudents)
      const student = gradebook.studentsThatCanSeeAssignment('2301')['1101']
      strictEqual(student.enrollments[0].grades.html_url, 'http://example.url/')
    })

    test('does not escape the name of the student', () => {
      gradebook.gotChunkOfStudents(allStudents)
      const student = gradebook.studentsThatCanSeeAssignment('2301')['1101']
      strictEqual(student.name, 'A`dam Jone`s')
    })

    test('does not escape the first name of the student', () => {
      gradebook.gotChunkOfStudents(allStudents)
      const student = gradebook.studentsThatCanSeeAssignment('2301')['1101']
      strictEqual(student.first_name, 'A`dam')
    })

    test('does not escape the last name of the student', () => {
      gradebook.gotChunkOfStudents(allStudents)
      const student = gradebook.studentsThatCanSeeAssignment('2301')['1101']
      strictEqual(student.last_name, 'Jone`s')
    })

    test('does not escape the sortable name of the student', () => {
      gradebook.gotChunkOfStudents(allStudents)
      const student = gradebook.studentsThatCanSeeAssignment('2301')['1101']
      strictEqual(student.sortable_name, 'Jone`s, A`dam')
    })

    test('returns all students when the assignment is visible to everyone', () => {
      gradebook.gotChunkOfStudents(allStudents)
      const students = gradebook.studentsThatCanSeeAssignment('2301')
      deepEqual(Object.keys(students).sort(), ['1101', '1102'])
    })

    test('returns only students with visibility when the assignment is not visible to everyone', () => {
      gradebook.gotChunkOfStudents(allStudents)
      const students = gradebook.studentsThatCanSeeAssignment('2302')
      deepEqual(Object.keys(students), ['1102'])
    })

    test('returns an empty collection when related students are not loaded', () => {
      gradebook.gotChunkOfStudents(allStudents.slice(0, 1))
      const students = gradebook.studentsThatCanSeeAssignment('2302')
      deepEqual(Object.keys(students), [])
    })

    test('returns an up-to-date collection when student data has changed', () => {
      // this ensures cached visibility data is invalidated when student data changes
      gradebook.gotChunkOfStudents(allStudents.slice(0, 1))
      let students = gradebook.studentsThatCanSeeAssignment('2302') // first cache
      gradebook.gotChunkOfStudents(allStudents.slice(1, 2))
      students = gradebook.studentsThatCanSeeAssignment('2302') // re-cache
      deepEqual(Object.keys(students), ['1102'])
    })

    test('includes test students', function () {
      gradebook.gotChunkOfStudents(allStudents)

      const testStudent = {
        id: '9901',
        name: 'Test Student',
        enrollments: [{type: 'StudentViewEnrollment', grades: {html_url: 'http://example.ur/'}}],
      }
      gradebook.gotChunkOfStudents([testStudent])
      const students = gradebook.studentsThatCanSeeAssignment('2301')
      deepEqual(Object.keys(students), ['1101', '1102', '9901'])
    })
  })

  QUnit.module('#visibleStudentsThatCanSeeAssignment', hooks => {
    hooks.beforeEach(() => {
      gradebook.gotChunkOfStudents(allStudents)
      gradebook.courseContent.students.setStudentIds(['1101', '1102'])
      gradebook.updateFilteredStudentIds()
    })

    test('includes students who can see the assignment when no filters are active', () => {
      const students = gradebook.visibleStudentsThatCanSeeAssignment('2302')
      ok(Object.keys(students).includes('1102'))
    })

    test('includes students who can see the assignment and match the active filters', () => {
      gradebook.filteredStudentIds = ['1102']
      gradebook.courseContent.students.setStudentIds(['1101', '1102'])

      const students = gradebook.visibleStudentsThatCanSeeAssignment('2302')
      ok(Object.keys(students).includes('1102'))
    })

    test('excludes students who cannot see the assignment', () => {
      const students = gradebook.visibleStudentsThatCanSeeAssignment('2302')
      notOk(Object.keys(students).includes('1101'))
    })

    test('excludes students who can see the assignment but do not match active filters', () => {
      gradebook.filteredStudentIds = ['1102']
      gradebook.courseContent.students.setStudentIds(['1101'])

      const students = gradebook.visibleStudentsThatCanSeeAssignment('2302')
      notOk(Object.keys(students).includes('1102'))
    })

    test('excludes students who can see the assignment but do not match the current search', () => {
      gradebook.filteredStudentIds = ['1101']

      const students = gradebook.visibleStudentsThatCanSeeAssignment('2302')
      notOk(Object.keys(students).includes('1102'))
    })
  })
})

QUnit.module('Gradebook#assignmentsLoadedForCurrentView', hooks => {
  let gradebook

  hooks.beforeEach(() => {
    gradebook = createGradebook()
  })

  test('returns false when assignments are not loaded', () => {
    strictEqual(gradebook.assignmentsLoadedForCurrentView(), false)
  })

  test('returns true when assignments are loaded', () => {
    gradebook.setAssignmentsLoaded()
    strictEqual(gradebook.assignmentsLoadedForCurrentView(), true)
  })

  QUnit.module('when grading periods are used', contextHooks => {
    contextHooks.beforeEach(() => {
      gradebook.contentLoadStates.assignmentsLoaded = {
        all: false,
        gradingPeriod: {2: false, 14: false},
      }
      gradebook.gradingPeriodId = '14'
    })

    test('returns true when assignments are loaded for the current grading period', () => {
      gradebook.setAssignmentsLoaded(['14'])
      strictEqual(gradebook.assignmentsLoadedForCurrentView(), true)
    })

    test('returns false when assignments are not loaded', () => {
      strictEqual(gradebook.assignmentsLoadedForCurrentView(), false)
    })

    test('returns false when assignments are loaded, but not for the current grading period', () => {
      gradebook.setAssignmentsLoaded(['2'])
      strictEqual(gradebook.assignmentsLoadedForCurrentView(), false)
    })
  })
})
