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

import {createGradebook, setFixtureHtml} from '../GradebookSpecHelper'

describe('Gradebook > Students', () => {
  let $container
  let gradebook

  beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))
    setFixtureHtml($container)
  })

  afterEach(() => {
    gradebook.destroy()
    $container.remove()
  })

  function getStudent(studentId) {
    return gradebook.student(studentId)
  }

  function getStudentRow(studentId) {
    return gradebook.gridData.rows.find(row => row.id === studentId)
  }

  describe('#updateStudentIds()', () => {
    let studentIds

    beforeEach(() => {
      gradebook = createGradebook()
      studentIds = ['1101', '1102', '1103']
    })

    it('stores the loaded student ids in the Gradebook', () => {
      gradebook.updateStudentIds(studentIds)
      expect(gradebook.courseContent.students.listStudentIds()).toEqual(studentIds)
    })

    it('sets the student ids loaded status to true', () => {
      gradebook.updateStudentIds(studentIds)
      expect(gradebook.contentLoadStates.studentIdsLoaded).toBe(true)
    })

    it('resets student assignment student visibility', () => {
      gradebook.assignmentStudentVisibility = {2301: ['1101', '1102']}
      gradebook.updateStudentIds(studentIds)
      expect(gradebook.assignmentStudentVisibility).toEqual({})
    })

    it('rebuilds grid rows', () => {
      jest.spyOn(gradebook, 'buildRows')
      gradebook.updateStudentIds(studentIds)
      expect(gradebook.buildRows).toHaveBeenCalledTimes(1)
    })

    it('rebuilds grid rows after storing the student ids', () => {
      jest.spyOn(gradebook, 'buildRows').mockImplementation(() => {
        expect(gradebook.courseContent.students.listStudentIds()).toEqual(studentIds)
      })
      gradebook.updateStudentIds(studentIds)
    })

    it('rebuilds grid rows after updating assignment student visibility', () => {
      gradebook.assignmentStudentVisibility = {2301: ['1101', '1102']}
      jest.spyOn(gradebook, 'buildRows').mockImplementation(() => {
        expect(gradebook.assignmentStudentVisibility).toEqual({})
      })
      gradebook.updateStudentIds(studentIds)
    })

    it('updates essential data load status', () => {
      jest.spyOn(gradebook, '_updateEssentialDataLoaded')
      gradebook.updateStudentIds(studentIds)
      expect(gradebook._updateEssentialDataLoaded).toHaveBeenCalledTimes(1)
    })

    it('updates essential data load status after updating student ids loaded status', () => {
      jest.spyOn(gradebook, 'renderFilters')
      jest.spyOn(gradebook, '_updateEssentialDataLoaded').mockImplementation(() => {
        expect(gradebook.contentLoadStates.studentIdsLoaded).toBe(true)
      })
      gradebook.updateStudentIds(studentIds)
    })

    it('updates essential data load status after building rows', () => {
      jest.spyOn(gradebook, 'buildRows')
      jest.spyOn(gradebook, '_updateEssentialDataLoaded').mockImplementation(() => {
        expect(gradebook.buildRows).toHaveBeenCalledTimes(1)
      })
      gradebook.updateStudentIds(studentIds)
    })
  })

  describe('#updateStudentsLoaded()', () => {
    beforeEach(() => {
      gradebook = createGradebook()
    })

    it('optionally sets the students loaded status to true', () => {
      gradebook.updateStudentsLoaded(true)
      expect(gradebook.contentLoadStates.studentsLoaded).toBe(true)
    })

    it('optionally sets the students loaded status to false', () => {
      gradebook.updateStudentsLoaded(false)
      expect(gradebook.contentLoadStates.studentsLoaded).toBe(false)
    })

    it('updates column headers when the grid has rendered', () => {
      jest.spyOn(gradebook, '_gridHasRendered').mockReturnValue(true)
      jest.spyOn(gradebook, 'updateColumnHeaders')
      gradebook.updateStudentsLoaded(true)
      expect(gradebook.updateColumnHeaders).toHaveBeenCalledTimes(1)
    })

    it('updates column headers after updating the students loaded status', () => {
      jest.spyOn(gradebook, '_gridHasRendered').mockReturnValue(true)
      jest.spyOn(gradebook, 'updateColumnHeaders').mockImplementation(() => {
        expect(gradebook.contentLoadStates.studentsLoaded).toBe(true)
      })
      gradebook.updateStudentsLoaded(true)
    })

    it('does not update column headers when the grid has not yet rendered', () => {
      jest.spyOn(gradebook, '_gridHasRendered').mockReturnValue(false)
      jest.spyOn(gradebook, 'updateColumnHeaders')
      gradebook.updateStudentsLoaded(true)
      expect(gradebook.updateColumnHeaders).not.toHaveBeenCalled()
    })

    it('renders filters', () => {
      jest.spyOn(gradebook, 'renderFilters')
      gradebook.updateStudentsLoaded(true)
      expect(gradebook.renderFilters).toHaveBeenCalledTimes(1)
    })

    it('renders filters after updating the students loaded status', () => {
      jest.spyOn(gradebook, 'renderFilters').mockImplementation(() => {
        expect(gradebook.contentLoadStates.studentsLoaded).toBe(true)
      })
      gradebook.updateStudentsLoaded(true)
    })

    it('updates the total grade column when students and submissions are loaded', () => {
      gradebook.setSubmissionsLoaded(true)
      jest.spyOn(gradebook, 'updateTotalGradeColumn')
      gradebook.updateStudentsLoaded(true)
      expect(gradebook.updateTotalGradeColumn).toHaveBeenCalledTimes(1)
    })

    it('updates the total grade column after updating the students loaded status', () => {
      gradebook.setSubmissionsLoaded(true)
      jest.spyOn(gradebook, 'updateTotalGradeColumn').mockImplementation(() => {
        expect(gradebook.contentLoadStates.studentsLoaded).toBe(true)
      })
      gradebook.updateStudentsLoaded(true)
    })

    it('does not update the total grade column when submissions are not loaded', () => {
      gradebook.setSubmissionsLoaded(false)
      jest.spyOn(gradebook, 'updateTotalGradeColumn')
      gradebook.updateStudentsLoaded(true)
      expect(gradebook.updateTotalGradeColumn).not.toHaveBeenCalled()
    })

    it('does not update the total grade column when students are being reloaded', () => {
      gradebook.setSubmissionsLoaded(true)
      gradebook.setStudentsLoaded(true)
      jest.spyOn(gradebook, 'updateTotalGradeColumn')
      gradebook.updateStudentsLoaded(false)
      expect(gradebook.updateTotalGradeColumn).not.toHaveBeenCalled()
    })
  })

  describe('#gotChunkOfStudents()', () => {
    let studentData

    beforeEach(() => {
      gradebook = createGradebook()
      jest.spyOn(gradebook.gradebookGrid, 'render').mockImplementation(() => {})

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

    it('updates the student map with each student', () => {
      gradebook.gotChunkOfStudents(studentData)
      expect(gradebook.students[1101]).toBeTruthy()
      expect(gradebook.students[1102]).toBeTruthy()
    })

    it('replaces matching students in the student map', () => {
      gradebook.gotChunkOfStudents(studentData)
      expect(gradebook.students[1101].name).toBe('Adam Jones')
    })

    it('updates the test student map with each test student', () => {
      gradebook.gotChunkOfStudents(studentData)
      expect(gradebook.studentViewStudents[1199]).toBeTruthy()
    })

    it('replaces matching students in the test student map', () => {
      gradebook.courseContent.students.addTestStudents([{id: '1199'}])
      gradebook.gotChunkOfStudents(studentData)
      expect(gradebook.studentViewStudents[1199].name).toBe('Test Student')
    })

    it('defaults the computed current score for each student to 0', () => {
      gradebook.gotChunkOfStudents(studentData)
      ;['1101', '1102', '1199'].forEach(studentId => {
        expect(getStudent(studentId).computed_current_score).toBe(0)
      })
    })

    it('preserves an existing computed current score', () => {
      studentData[0].computed_current_score = 95
      gradebook.gotChunkOfStudents(studentData)
      expect(getStudent('1101').computed_current_score).toBe('95')
    })

    it('defaults the computed final score for each student to 0', () => {
      gradebook.gotChunkOfStudents(studentData)
      ;['1101', '1102', '1199'].forEach(studentId => {
        expect(getStudent(studentId).computed_final_score).toBe(0)
      })
    })

    it('preserves an existing computed final score', () => {
      studentData[0].computed_final_score = 95
      gradebook.gotChunkOfStudents(studentData)
      expect(getStudent('1101').computed_final_score).toBe('95')
    })

    it('sets a student as "concluded" when all enrollments for that student are "completed"', () => {
      const {enrollments} = studentData[0]
      enrollments[0].enrollment_state = 'completed'
      enrollments.push({
        enrollment_state: 'completed',
        grades: {html_url: 'http://example.url/'},
        type: 'StudentEnrollment',
      })
      gradebook.gotChunkOfStudents(studentData)
      expect(getStudent('1101').isConcluded).toBe(true)
    })

    it('sets a student as "not concluded" when not all enrollments for that student are "completed"', () => {
      studentData[0].enrollments.push({
        enrollment_state: 'completed',
        grades: {html_url: 'http://example.url/'},
        type: 'StudentEnrollment',
      })
      gradebook.gotChunkOfStudents(studentData)
      expect(getStudent('1101').isConcluded).toBe(false)
    })

    it('sets a student as "inactive" when all enrollments for that student are "inactive"', () => {
      const {enrollments} = studentData[0]
      enrollments[0].enrollment_state = 'inactive'
      enrollments.push({
        enrollment_state: 'inactive',
        grades: {html_url: 'http://example.url/'},
        type: 'StudentEnrollment',
      })
      gradebook.gotChunkOfStudents(studentData)
      expect(getStudent('1101').isInactive).toBe(true)
    })

    it('sets a student as "not inactive" when not all enrollments for that student are "inactive"', () => {
      studentData[0].enrollments.push({
        enrollment_state: 'inactive',
        grades: {html_url: 'http://example.url/'},
        type: 'StudentEnrollment',
      })
      gradebook.gotChunkOfStudents(studentData)
      expect(getStudent('1101').isInactive).toBe(false)
    })

    it('sets the css class on the row for each student', () => {
      gradebook.gotChunkOfStudents(studentData)
      ;['1101', '1102', '1199'].forEach(studentId => {
        expect(getStudentRow(studentId).cssClass).toBe(`student_${studentId}`)
      })
    })

    it('builds rows', () => {
      gradebook.searchFilteredStudentIds = [1101]
      jest.spyOn(gradebook, 'buildRows')
      gradebook.gotChunkOfStudents(studentData)
      expect(gradebook.buildRows).toHaveBeenCalledTimes(1)
    })
  })

  describe('#isStudentGradeable()', () => {
    beforeEach(() => {
      gradebook = createGradebook()
      gradebook.students = {1101: {id: '1101', isConcluded: false}}
    })

    it('returns true when the student enrollment is active', () => {
      expect(gradebook.isStudentGradeable('1101')).toBe(true)
    })

    it('returns false when the student enrollment is concluded', () => {
      gradebook.students[1101].isConcluded = true
      expect(gradebook.isStudentGradeable('1101')).toBe(false)
    })

    it('returns false when the student is not loaded', () => {
      delete gradebook.students[1101]
      expect(gradebook.isStudentGradeable('1101')).toBe(false)
    })
  })

  describe('#studentCanReceiveGradeOverride()', () => {
    let submissionData

    beforeEach(() => {
      gradebook = createGradebook()

      const studentData = [
        {
          enrollments: [
            {
              type: 'StudentEnrollment',
              grades: {html_url: 'http://example.url/'},
            },
          ],
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

    it('returns true when the student has been graded on one assignment', () => {
      gradebook.gotSubmissionsChunk(submissionData)
      expect(gradebook.studentCanReceiveGradeOverride('1101')).toBe(true)
    })

    it('returns false when the student has not been graded on any assignments', () => {
      submissionData[0].submissions[0].workflow_state = 'submitted'
      submissionData[0].submissions[1].workflow_state = 'unsubmitted'
      gradebook.gotSubmissionsChunk(submissionData)
      expect(gradebook.studentCanReceiveGradeOverride('1101')).toBe(false)
    })

    it('considers a submission with a cleared grade to be not yet graded', () => {
      submissionData[0].submissions[0].score = null
      submissionData[0].submissions[1].score = null
      gradebook.gotSubmissionsChunk(submissionData)
      expect(gradebook.studentCanReceiveGradeOverride('1101')).toBe(false)
    })

    it('considers an excused submission to be graded', () => {
      submissionData[0].submissions[0].excused = true
      submissionData[0].submissions[1].workflow_state = 'submitted'
      gradebook.gotSubmissionsChunk(submissionData)
      expect(gradebook.studentCanReceiveGradeOverride('1101')).toBe(true)
    })

    it('returns false when the student is not assigned to any assignments', () => {
      expect(gradebook.studentCanReceiveGradeOverride('1101')).toBe(false)
    })

    it('returns false when the student enrollment is concluded', () => {
      gradebook.gotSubmissionsChunk(submissionData)
      gradebook.students[1101].isConcluded = true
      expect(gradebook.studentCanReceiveGradeOverride('1101')).toBe(false)
    })

    it('returns false when the student is not loaded', () => {
      gradebook.gotSubmissionsChunk(submissionData)
      delete gradebook.students[1101]
      expect(gradebook.studentCanReceiveGradeOverride('1101')).toBe(false)
    })
  })
})
