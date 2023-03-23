/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
  createGradebook,
  setFixtureHtml,
} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'

QUnit.module('Gradebook > Students', suiteHooks => {
  let $container
  let gradebook

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))
    setFixtureHtml($container)
  })

  suiteHooks.afterEach(() => {
    gradebook.destroy()
    $container.remove()
  })

  function getStudent(studentId) {
    return gradebook.student(studentId)
  }

  function getStudentRow(studentId) {
    return gradebook.gridData.rows.find(row => row.id === studentId)
  }

  QUnit.module('#updateStudentIds()', hooks => {
    let studentIds

    hooks.beforeEach(() => {
      gradebook = createGradebook()
      studentIds = ['1101', '1102', '1103']
    })

    test('stores the loaded student ids in the Gradebook', () => {
      gradebook.updateStudentIds(studentIds)
      deepEqual(gradebook.courseContent.students.listStudentIds(), studentIds)
    })

    test('sets the student ids loaded status to true', () => {
      gradebook.updateStudentIds(studentIds)
      strictEqual(gradebook.contentLoadStates.studentIdsLoaded, true)
    })

    test('resets student assignment student visibility', () => {
      gradebook.assignmentStudentVisibility = {2301: ['1101', '1102']}
      gradebook.updateStudentIds(studentIds)
      deepEqual(gradebook.assignmentStudentVisibility, {})
    })

    test('rebuilds grid rows', () => {
      sinon.stub(gradebook, 'buildRows')
      gradebook.updateStudentIds(studentIds)
      strictEqual(gradebook.buildRows.callCount, 1)
    })

    test('rebuilds grid rows after storing the student ids', () => {
      sinon.stub(gradebook, 'buildRows').callsFake(() => {
        deepEqual(gradebook.courseContent.students.listStudentIds(), studentIds)
      })
      gradebook.updateStudentIds(studentIds)
    })

    test('rebuilds grid rows after updating assignment student visibility', () => {
      gradebook.assignmentStudentVisibility = {2301: ['1101', '1102']}
      sinon.stub(gradebook, 'buildRows').callsFake(() => {
        deepEqual(gradebook.assignmentStudentVisibility, {})
      })
      gradebook.updateStudentIds(studentIds)
    })

    test('updates essential data load status', () => {
      sinon.spy(gradebook, '_updateEssentialDataLoaded')
      gradebook.updateStudentIds(studentIds)
      strictEqual(gradebook._updateEssentialDataLoaded.callCount, 1)
    })

    test('updates essential data load status after updating student ids loaded status', () => {
      sinon.spy(gradebook, 'renderFilters')
      sinon.stub(gradebook, '_updateEssentialDataLoaded').callsFake(() => {
        strictEqual(gradebook.contentLoadStates.studentIdsLoaded, true)
      })
      gradebook.updateStudentIds(studentIds)
    })

    test('updates essential data load status after building rows', () => {
      sinon.spy(gradebook, 'buildRows')
      sinon.stub(gradebook, '_updateEssentialDataLoaded').callsFake(() => {
        strictEqual(gradebook.buildRows.callCount, 1)
      })
      gradebook.updateStudentIds(studentIds)
    })
  })

  QUnit.module('#updateStudentsLoaded()', hooks => {
    hooks.beforeEach(() => {
      gradebook = createGradebook()
    })

    test('optionally sets the students loaded status to true', () => {
      gradebook.updateStudentsLoaded(true)
      strictEqual(gradebook.contentLoadStates.studentsLoaded, true)
    })

    test('optionally sets the students loaded status to false', () => {
      gradebook.updateStudentsLoaded(false)
      strictEqual(gradebook.contentLoadStates.studentsLoaded, false)
    })

    test('updates column headers when the grid has rendered', () => {
      sinon.stub(gradebook, '_gridHasRendered').returns(true)
      sinon.spy(gradebook, 'updateColumnHeaders')
      gradebook.updateStudentsLoaded(true)
      strictEqual(gradebook.updateColumnHeaders.callCount, 1)
    })

    test('updates column headers after updating the students loaded status', () => {
      sinon.stub(gradebook, '_gridHasRendered').returns(true)
      sinon.stub(gradebook, 'updateColumnHeaders').callsFake(() => {
        strictEqual(gradebook.contentLoadStates.studentsLoaded, true)
      })
      gradebook.updateStudentsLoaded(true)
    })

    test('does not update column headers when the grid has not yet rendered', () => {
      sinon.stub(gradebook, '_gridHasRendered').returns(false)
      sinon.spy(gradebook, 'updateColumnHeaders')
      gradebook.updateStudentsLoaded(true)
      strictEqual(gradebook.updateColumnHeaders.callCount, 0)
    })

    test('renders filters', () => {
      sinon.spy(gradebook, 'renderFilters')
      gradebook.updateStudentsLoaded(true)
      strictEqual(gradebook.renderFilters.callCount, 1)
    })

    test('renders filters after updating the students loaded status', () => {
      sinon.stub(gradebook, 'renderFilters').callsFake(() => {
        strictEqual(gradebook.contentLoadStates.studentsLoaded, true)
      })
      gradebook.updateStudentsLoaded(true)
    })

    test('updates the total grade column when students and submissions are loaded', () => {
      gradebook.setSubmissionsLoaded(true)
      sinon.spy(gradebook, 'updateTotalGradeColumn')
      gradebook.updateStudentsLoaded(true)
      strictEqual(gradebook.updateTotalGradeColumn.callCount, 1)
    })

    test('updates the total grade column after updating the students loaded status', () => {
      gradebook.setSubmissionsLoaded(true)
      sinon.stub(gradebook, 'updateTotalGradeColumn').callsFake(() => {
        strictEqual(gradebook.contentLoadStates.studentsLoaded, true)
      })
      gradebook.updateStudentsLoaded(true)
    })

    test('does not update the total grade column when submissions are not loaded', () => {
      gradebook.setSubmissionsLoaded(false)
      sinon.spy(gradebook, 'updateTotalGradeColumn')
      gradebook.updateStudentsLoaded(true)
      strictEqual(gradebook.updateTotalGradeColumn.callCount, 0)
    })

    test('does not update the total grade column when students are being reloaded', () => {
      gradebook.setSubmissionsLoaded(true)
      gradebook.setStudentsLoaded(true)
      sinon.spy(gradebook, 'updateTotalGradeColumn')
      gradebook.updateStudentsLoaded(false)
      strictEqual(gradebook.updateTotalGradeColumn.callCount, 0)
    })
  })

  QUnit.module('#gotChunkOfStudents()', hooks => {
    let studentData

    hooks.beforeEach(() => {
      gradebook = createGradebook()
      sinon.stub(gradebook.gradebookGrid, 'render')

      studentData = [
        {
          id: '1101',
          name: 'Adam Jones',
          enrollments: [
            {
              enrollment_state: 'active',
              grades: {html_url: 'http://canvas/courses/1201/users/1101'},
              type: 'StudentEnrollment',
            },
          ],
        },

        {
          id: '1102',
          name: 'Betty Ford',
          enrollments: [
            {
              enrollment_state: 'active',
              grades: {html_url: 'http://canvas/courses/1201/users/1102'},
              type: 'StudentEnrollment',
            },
          ],
        },

        {
          id: '1199',
          name: 'Test Student',
          enrollments: [
            {
              enrollment_state: 'active',
              grades: {html_url: 'http://canvas/courses/1201/users/1199'},
              type: 'StudentViewEnrollment',
            },
          ],
        },
      ]

      gradebook.courseContent.students.setStudentIds(['1101', '1102', '1199'])
      gradebook.buildRows()
    })

    test('updates the student map with each student', () => {
      gradebook.gotChunkOfStudents(studentData)
      ok(gradebook.students[1101], 'student map includes Adam Jones')
      ok(gradebook.students[1102], 'student map includes Betty Ford')
    })

    test('replaces matching students in the student map', () => {
      gradebook.gotChunkOfStudents(studentData)
      equal(gradebook.students[1101].name, 'Adam Jones')
    })

    test('updates the test student map with each test student', () => {
      gradebook.gotChunkOfStudents(studentData)
      ok(gradebook.studentViewStudents[1199], 'test student map includes Test Student')
    })

    test('replaces matching students in the test student map', () => {
      gradebook.courseContent.students.addTestStudents([{id: '1199'}])
      gradebook.gotChunkOfStudents(studentData)
      equal(gradebook.studentViewStudents[1199].name, 'Test Student')
    })

    test('defaults the computed current score for each student to 0', () => {
      gradebook.gotChunkOfStudents(studentData)
      ;['1101', '1102', '1199'].forEach(studentId => {
        strictEqual(getStudent(studentId).computed_current_score, 0)
      })
    })

    test('preserves an existing computed current score', () => {
      studentData[0].computed_current_score = 95
      gradebook.gotChunkOfStudents(studentData)
      strictEqual(getStudent('1101').computed_current_score, '95')
    })

    test('defaults the computed final score for each student to 0', () => {
      gradebook.gotChunkOfStudents(studentData)
      ;['1101', '1102', '1199'].forEach(studentId => {
        strictEqual(getStudent(studentId).computed_final_score, 0)
      })
    })

    test('preserves an existing computed final score', () => {
      studentData[0].computed_final_score = 95
      gradebook.gotChunkOfStudents(studentData)
      strictEqual(getStudent('1101').computed_final_score, '95')
    })

    test('sets a student as "concluded" when all enrollments for that student are "completed"', () => {
      const {enrollments} = studentData[0]
      enrollments[0].enrollment_state = 'completed'
      enrollments.push({
        enrollment_state: 'completed',
        grades: {html_url: 'http://example.url/'},
        type: 'StudentEnrollment',
      })
      gradebook.gotChunkOfStudents(studentData)
      strictEqual(getStudent('1101').isConcluded, true)
    })

    test('sets a student as "not concluded" when not all enrollments for that student are "completed"', () => {
      studentData[0].enrollments.push({
        enrollment_state: 'completed',
        grades: {html_url: 'http://example.url/'},
        type: 'StudentEnrollment',
      })
      gradebook.gotChunkOfStudents(studentData)
      strictEqual(getStudent('1101').isConcluded, false)
    })

    test('sets a student as "inactive" when all enrollments for that student are "inactive"', () => {
      const {enrollments} = studentData[0]
      enrollments[0].enrollment_state = 'inactive'
      enrollments.push({
        enrollment_state: 'inactive',
        grades: {html_url: 'http://example.url/'},
        type: 'StudentEnrollment',
      })
      gradebook.gotChunkOfStudents(studentData)
      strictEqual(getStudent('1101').isInactive, true)
    })

    test('sets a student as "not inactive" when not all enrollments for that student are "inactive"', () => {
      studentData[0].enrollments.push({
        enrollment_state: 'inactive',
        grades: {html_url: 'http://example.url/'},
        type: 'StudentEnrollment',
      })
      gradebook.gotChunkOfStudents(studentData)
      strictEqual(getStudent('1101').isInactive, false)
    })

    test('sets the css class on the row for each student', () => {
      gradebook.gotChunkOfStudents(studentData)
      ;['1101', '1102', '1199'].forEach(studentId => {
        equal(getStudentRow(studentId).cssClass, `student_${studentId}`)
      })
    })

    test('builds rows', () => {
      gradebook.searchFilteredStudentIds = [1101]
      sinon.spy(gradebook, 'buildRows')
      gradebook.gotChunkOfStudents(studentData)
      strictEqual(gradebook.buildRows.callCount, 1)
    })
  })

  QUnit.module('#isStudentGradeable()', hooks => {
    hooks.beforeEach(() => {
      gradebook = createGradebook()
      gradebook.students = {1101: {id: '1101', isConcluded: false}}
    })

    test('returns true when the student enrollment is active', () => {
      strictEqual(gradebook.isStudentGradeable('1101'), true)
    })

    test('returns false when the student enrollment is concluded', () => {
      gradebook.students[1101].isConcluded = true
      strictEqual(gradebook.isStudentGradeable('1101'), false)
    })

    test('returns false when the student is not loaded', () => {
      delete gradebook.students[1101]
      strictEqual(gradebook.isStudentGradeable('1101'), false)
    })
  })

  QUnit.module('#studentCanReceiveGradeOverride()', hooks => {
    let submissionData

    hooks.beforeEach(() => {
      gradebook = createGradebook()

      const studentData = [
        {
          enrollments: [{type: 'StudentEnrollment', grades: {html_url: 'http://example.url/'}}],
          id: '1101',
          name: 'Adam Jones',
        },
      ]
      gradebook.gotChunkOfStudents(studentData)

      gradebook.setAssignmentGroups({
        2201: {group_weight: 100},
      })

      gradebook.setAssignments({
        2301: {
          assignment_group_id: '2201',
          id: '2301',
          name: 'Math Assignment',
          published: true,
        },

        2302: {
          assignment_group_id: '2201',
          id: '2302',
          name: 'English Assignment',
          published: false,
        },
      })

      submissionData = [
        {
          submissions: [
            {
              assignment_id: '2301',
              assignment_visible: true,
              cached_due_date: '2015-10-15T12:00:00Z',
              id: '2501',
              score: 10,
              user_id: '1101',
              workflow_state: 'graded',
            },

            {
              assignment_id: '2302',
              assignment_visible: true,
              cached_due_date: '2015-12-15T12:00:00Z',
              id: '2502',
              score: 9,
              user_id: '1101',
              workflow_state: 'graded',
            },
          ],

          user_id: '1101',
        },
      ]
    })

    test('returns true when the student has been graded on one assignment', () => {
      gradebook.gotSubmissionsChunk(submissionData)
      strictEqual(gradebook.studentCanReceiveGradeOverride('1101'), true)
    })

    test('returns false when the student has not been graded on any assignments', () => {
      submissionData[0].submissions[0].workflow_state = 'submitted'
      submissionData[0].submissions[1].workflow_state = 'unsubmitted'
      gradebook.gotSubmissionsChunk(submissionData)
      strictEqual(gradebook.studentCanReceiveGradeOverride('1101'), false)
    })

    test('considers a submission with a cleared grade to be not yet graded', () => {
      submissionData[0].submissions[0].score = null
      submissionData[0].submissions[1].score = null
      gradebook.gotSubmissionsChunk(submissionData)
      strictEqual(gradebook.studentCanReceiveGradeOverride('1101'), false)
    })

    test('considers an excused submission to be graded', () => {
      submissionData[0].submissions[0].excused = true
      submissionData[0].submissions[1].workflow_state = 'submitted'
      gradebook.gotSubmissionsChunk(submissionData)
      strictEqual(gradebook.studentCanReceiveGradeOverride('1101'), true)
    })

    test('returns false when the student is not assigned to any assignments', () => {
      strictEqual(gradebook.studentCanReceiveGradeOverride('1101'), false)
    })

    test('returns false when the student enrollment is concluded', () => {
      gradebook.gotSubmissionsChunk(submissionData)
      gradebook.students[1101].isConcluded = true
      strictEqual(gradebook.studentCanReceiveGradeOverride('1101'), false)
    })

    test('returns false when the student is not loaded', () => {
      gradebook.gotSubmissionsChunk(submissionData)
      delete gradebook.students[1101]
      strictEqual(gradebook.studentCanReceiveGradeOverride('1101'), false)
    })
  })
})
