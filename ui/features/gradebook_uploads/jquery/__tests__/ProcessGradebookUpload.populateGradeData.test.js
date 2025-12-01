/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {isEmpty} from 'es-toolkit/compat'
import ProcessGradebookUpload from '../process_gradebook_upload'

// Define constants
const oldAssignment1 = {id: 1, title: 'Old Assignment 1', points_possible: 25, published: true}
const submissionWithNumericGrade = {assignment_id: 1, grade: 20, original_grade: 20}
const submissionOld1NoChange = {assignment_id: 1, grade: '20', original_grade: '20'}
const submissionOld1Change = {assignment_id: 1, grade: '20', original_grade: '25'}
const submissionOld1Excused = {assignment_id: 1, grade: 'EX', original_grade: '20'}

const oldAssignment2 = {id: 2, title: 'Old Assignment 2', points_possible: 25, published: true}
const submissionOld2Change = {assignment_id: 2, grade: '20', original_grade: '25'}
const submissionOld2Excused = {assignment_id: 2, grade: 'EX', original_grade: '20'}

const newAssignment1 = {id: 0, title: 'New Assignment 1', points_possible: 25, published: true}
const submissionNew1NoChange = {assignment_id: 0, grade: '20', original_grade: '20'}
const submissionNew1Change = {assignment_id: 0, grade: '20', original_grade: '25'}
const submissionNew1Excused = {assignment_id: 0, grade: 'EX', original_grade: '20'}
const submissionNew1VerboselyExcused = {assignment_id: 0, grade: 'Excused', original_grade: '20'}

const newAssignment2 = {id: -1, title: 'New Assignment 2', points_possible: 25, published: true}
const submissionNew2Change = {
  assignment_id: -1,
  grade: '20',
  original_grade: '25',
  type: 'assignment',
}
const submissionNew2Excused = {
  assignment_id: -1,
  grade: 'EX',
  original_grade: '20',
  type: 'assignment',
}

const submissionIgnored = {assignment_id: -2, grade: '25', original_grade: '25', type: 'assignment'}

function mapAssignments() {
  return {0: 3, '-1': 4}
}

describe('ProcessGradebookUpload.populateGradeDataPerSubmission', () => {
  test('rejects an unrecognized or ignored assignment', () => {
    const gradeData = {}
    ProcessGradebookUpload.populateGradeDataPerSubmission(submissionIgnored, 0, [], gradeData)

    expect(isEmpty(gradeData)).toBe(true)
  })

  test('does not alter a grade that requires no change', () => {
    const gradeData = {}
    ProcessGradebookUpload.populateGradeDataPerSubmission(submissionOld1NoChange, 0, [], gradeData)

    expect(isEmpty(gradeData)).toBe(true)
  })

  test('alters a grade on a new assignment', () => {
    const gradeData = {}
    const assignmentMap = mapAssignments()
    ProcessGradebookUpload.populateGradeDataPerSubmission(
      submissionNew1Change,
      0,
      assignmentMap,
      gradeData,
    )

    expect(gradeData[assignmentMap[submissionNew1Change.assignment_id]][0].posted_grade).toBe(
      submissionNew1Change.grade,
    )
  })

  test('alters a grade to excused on a new assignment if "EX" is supplied', () => {
    const gradeData = {}
    const assignmentMap = mapAssignments()
    ProcessGradebookUpload.populateGradeDataPerSubmission(
      submissionNew1Excused,
      0,
      assignmentMap,
      gradeData,
    )

    expect(gradeData[assignmentMap[submissionNew1Excused.assignment_id]][0].excuse).toBe(true)
  })

  test('alters a grade to excused on a new assignment if "Excused" is supplied', () => {
    const gradeData = {}
    const assignmentMap = mapAssignments()
    ProcessGradebookUpload.populateGradeDataPerSubmission(
      submissionNew1VerboselyExcused,
      0,
      assignmentMap,
      gradeData,
    )

    expect(gradeData[assignmentMap[submissionNew1Excused.assignment_id]][0].excuse).toBe(true)
  })

  test('alters a grade on an existing assignment', () => {
    const gradeData = {}
    ProcessGradebookUpload.populateGradeDataPerSubmission(submissionOld1Change, 0, [], gradeData)

    expect(gradeData[submissionOld1Change.assignment_id][0].posted_grade).toBe(
      submissionOld1Change.grade,
    )
  })

  test('alters a grade to excused on an existing assignment', () => {
    const gradeData = {}
    ProcessGradebookUpload.populateGradeDataPerSubmission(submissionOld1Excused, 0, [], gradeData)

    expect(gradeData[submissionOld1Excused.assignment_id][0].excuse).toBe(true)
  })

  test('handles numeric grades correctly', () => {
    const gradeData = {}
    ProcessGradebookUpload.populateGradeDataPerSubmission(
      submissionWithNumericGrade,
      0,
      [],
      gradeData,
    )

    // When grade is numeric and original_grade is also numeric and they're equal,
    // no change should be recorded
    expect(isEmpty(gradeData)).toBe(true)
  })
})

describe('ProcessGradebookUpload.populateGradeDataPerStudent', () => {
  test('can populate multiple assignment changes for a student', () => {
    const student = {
      previous_id: 0,
      submissions: [submissionOld1Change, submissionOld2Excused, submissionNew1Excused],
    }
    const assignmentMap = mapAssignments()
    const gradeData = {}
    ProcessGradebookUpload.populateGradeDataPerStudent(student, assignmentMap, gradeData)

    expect(gradeData[oldAssignment1.id][student.previous_id].posted_grade).toBe(
      submissionOld1Change.grade,
    )
    expect(gradeData[oldAssignment2.id][student.previous_id].excuse).toBe(true)
    expect(gradeData[assignmentMap[newAssignment1.id]][student.previous_id].excuse).toBe(true)
  })
})

describe('ProcessGradebookUpload.populateGradeData', () => {
  test('properly populates grade data', () => {
    const student1 = {
      previous_id: 1,
      submissions: [submissionOld1Change, submissionNew1Excused, submissionNew2Change],
    }
    const student2 = {
      previous_id: 2,
      submissions: [submissionOld2Excused, submissionNew1Change, submissionNew2Excused],
    }
    const gradebook = {
      students: [student1, student2],
      assignments: [oldAssignment1, oldAssignment2, newAssignment1, newAssignment2],
    }
    // Mock responses for new assignments
    const responses = [[{id: 3}], [{id: 4}]]
    const gradeData = ProcessGradebookUpload.populateGradeData(gradebook, responses)

    expect(gradeData[oldAssignment1.id][student1.previous_id].posted_grade).toBe(
      submissionOld1Change.grade,
    )
    expect(gradeData[oldAssignment2.id][student2.previous_id].excuse).toBe(true)
    expect(gradeData[3][student1.previous_id].excuse).toBe(true) // newAssignment1 gets id 3
    expect(gradeData[3][student2.previous_id].posted_grade).toBe(submissionNew1Change.grade)
    expect(gradeData[4][student1.previous_id].posted_grade).toBe(
      // newAssignment2 gets id 4
      submissionNew2Change.grade,
    )
    expect(gradeData[4][student2.previous_id].excuse).toBe(true)
  })
})

describe('ProcessGradebookUpload.parseCustomColumnData', () => {
  const customColumn = {id: 10, title: 'Notes'}
  const customData = ({student_id, column_id, new_content}) => ({
    student_id,
    column_id,
    new_content,
  })

  test.skip('correctly parses data for one student', () => {
    const data = ProcessGradebookUpload.parseCustomColumnData(
      [{id: 5, custom_column_data: [{column_id: 10, new_content: 'B'}]}],
      [customColumn],
    )
    const expectedData = [customData({student_id: 5, column_id: 10, new_content: 'B'})]
    expect(data).toEqual(expectedData)
  })

  test.skip('correctly parses data for multiple students', () => {
    const data = ProcessGradebookUpload.parseCustomColumnData(
      [
        {id: 5, custom_column_data: [{column_id: 10, new_content: 'B'}]},
        {id: 6, custom_column_data: [{column_id: 10, new_content: 'C'}]},
        {id: 7, custom_column_data: [{column_id: 10, new_content: 'D'}]},
      ],
      [customColumn],
    )
    const expectedData = [
      customData({student_id: 5, column_id: 10, new_content: 'B'}),
      customData({student_id: 6, column_id: 10, new_content: 'C'}),
      customData({student_id: 7, column_id: 10, new_content: 'D'}),
    ]
    expect(data).toEqual(expectedData)
  })
})
