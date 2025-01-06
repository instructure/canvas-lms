/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import _ from 'lodash'
import sinon from 'sinon'
import ProcessGradebookUpload from '../process_gradebook_upload'
import fakeENV from '@canvas/test-utils/fakeENV'

// Define constants
const oldAssignment1 = {id: 1, title: 'Old Assignment 1', points_possible: 25, published: true}

const submissionWithNumericGrade = {assignment_id: 1, grade: 20, original_grade: '20'}
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

const customColumn1 = {id: 1, title: 'Notes', read_only: false}

const createAssignmentResponse1 = {id: 3}
const createAssignmentResponse2 = {id: 4}

const progressQueued = {id: 1, workflow_state: 'queued'}
const progressCompleted = {id: 1, workflow_state: 'completed'}

function mapAssignments() {
  return {0: 3, '-1': 4}
}

let xhr
let requests

let goToGradebookStub

let clock

function equalAssignment(assignment1, assignment2) {
  expect(assignment1.name).toBe(assignment2.title)
  expect(assignment1.points_possible).toBe(assignment2.points_possible)
  expect(assignment1.published).toBe(assignment2.published)
}

describe('ProcessGradebookUpload.getNewAssignmentsFromGradebook', () => {
  test('returns an empty array if the gradebook given has a single assignment with no id', () => {
    const gradebook = {assignments: [{key: 'value'}]}
    const assignments = ProcessGradebookUpload.getNewAssignmentsFromGradebook(gradebook)

    expect(assignments).toHaveLength(0)
  })

  test('returns an empty array if the gradebook given has a single assignment with a null id', () => {
    const gradebook = {assignments: [{id: null, key: 'value'}]}
    const assignments = ProcessGradebookUpload.getNewAssignmentsFromGradebook(gradebook)

    expect(assignments).toHaveLength(0)
  })

  test('returns an empty array if the gradebook given has a single assignment with positive id', () => {
    const gradebook = {assignments: [{id: 1}]}
    const assignments = ProcessGradebookUpload.getNewAssignmentsFromGradebook(gradebook)

    expect(assignments).toHaveLength(0)
  })

  test('returns an array with one assignment if gradebook given has a single assignment with zero id', () => {
    const gradebook = {assignments: [{id: 0}]}
    const assignments = ProcessGradebookUpload.getNewAssignmentsFromGradebook(gradebook)

    expect(assignments).toHaveLength(1)
    expect(assignments[0].id).toBe(0)
  })

  test('returns an array with one assignment if the gradebook given has a single assignment with negative id', () => {
    const gradebook = {assignments: [{id: -1}]}
    const assignments = ProcessGradebookUpload.getNewAssignmentsFromGradebook(gradebook)

    expect(assignments).toHaveLength(1)
    expect(assignments[0].id).toBe(-1)
  })

  test('returns an array with only the assignments with non positive ids if the gradebook given has all ids', () => {
    const gradebook = {assignments: [{id: -1}, {id: 0}, {id: 1}]}
    const assignments = ProcessGradebookUpload.getNewAssignmentsFromGradebook(gradebook)

    expect(assignments).toHaveLength(2)
    expect(assignments[0].id).toBeLessThan(1)
    expect(assignments[1].id).toBeLessThan(1)
  })
})

describe('ProcessGradebookUpload.createIndividualAssignment', () => {
  beforeEach(() => {
    // Setup fake XMLHttpRequest
    xhr = sinon.useFakeXMLHttpRequest()
    requests = []

    xhr.onCreate = function (request) {
      requests.push(request)
    }

    // Setup fake environment
    fakeENV.setup()
    window.ENV = window.ENV || {}
    window.ENV.create_assignment_path = '/create_assignment_path/url'
  })

  afterEach(() => {
    // Restore fake XMLHttpRequest and environment
    xhr.restore()
    fakeENV.teardown()
  })

  test('properly creates a new assignment', () => {
    ProcessGradebookUpload.createIndividualAssignment(oldAssignment1)

    expect(requests).toHaveLength(1)
    expect(requests[0].url).toBe('/create_assignment_path/url')
    expect(requests[0].method).toBe('POST')

    const createAssignmentRequest = JSON.parse(requests[0].requestBody)
    equalAssignment(createAssignmentRequest.assignment, oldAssignment1)
  })
})

describe('ProcessGradebookUpload.createAssignments', () => {
  beforeEach(() => {
    // Setup fake XMLHttpRequest
    xhr = sinon.useFakeXMLHttpRequest()
    requests = []

    xhr.onCreate = function (request) {
      requests.push(request)
    }

    // Setup fake environment
    fakeENV.setup()
    window.ENV = window.ENV || {}
    window.ENV.create_assignment_path = '/create_assignment_path/url'
  })

  afterEach(() => {
    // Restore fake XMLHttpRequest and environment
    xhr.restore()
    fakeENV.teardown()
  })

  test('sends no data to server and returns an empty array if given no assignments', () => {
    const gradebook = {assignments: []}
    const responses = ProcessGradebookUpload.createAssignments(gradebook)

    expect(requests).toHaveLength(0)
    expect(responses).toHaveLength(0)
  })

  test('properly filters and creates multiple assignments', () => {
    const gradebook = {
      assignments: [oldAssignment1, oldAssignment2, newAssignment1, newAssignment2],
    }
    ProcessGradebookUpload.createAssignments(gradebook)

    expect(requests).toHaveLength(2)

    expect(requests[0].url).toBe('/create_assignment_path/url')
    expect(requests[0].method).toBe('POST')

    const createAssignmentRequest1 = JSON.parse(requests[0].requestBody)
    equalAssignment(createAssignmentRequest1.assignment, newAssignment1)

    expect(requests[1].url).toBe('/create_assignment_path/url')
    expect(requests[1].method).toBe('POST')

    const createAssignmentRequest2 = JSON.parse(requests[1].requestBody)
    equalAssignment(createAssignmentRequest2.assignment, newAssignment2)
  })

  test('sends calculate_grades: false as an argument when creating assignments', () => {
    const gradebook = {
      assignments: [newAssignment1],
    }
    ProcessGradebookUpload.createAssignments(gradebook)

    const createAssignmentRequest = JSON.parse(requests[0].requestBody)
    expect(createAssignmentRequest.calculate_grades).toBe(false)
  })
})

describe('ProcessGradebookUpload.mapLocalAssignmentsToDatabaseAssignments', () => {
  test('properly pairs if length is 1 and responses is not an array of arrays', () => {
    const gradebook = {assignments: [newAssignment1]}
    const responses = [{id: 3}]
    const assignmentMap = ProcessGradebookUpload.mapLocalAssignmentsToDatabaseAssignments(
      gradebook,
      responses,
    )

    expect(assignmentMap[newAssignment1.id]).toBe(responses[0].id)
  })

  test('properly pairs if length is not 1 and responses is an array of arrays', () => {
    const gradebook = {assignments: [newAssignment1, newAssignment2]}
    const responses = [[{id: 3}], [{id: 4}]]
    const assignmentMap = ProcessGradebookUpload.mapLocalAssignmentsToDatabaseAssignments(
      gradebook,
      responses,
    )

    expect(assignmentMap[newAssignment1.id]).toBe(responses[0][0].id)
    expect(assignmentMap[newAssignment2.id]).toBe(responses[1][0].id)
  })

  test('does not attempt to pair assignments that do not have a negative id', () => {
    const gradebook = {
      assignments: [newAssignment1, oldAssignment1, oldAssignment2, newAssignment2],
    }
    const responses = [[{id: 3}], [{id: 4}]]
    const assignmentMap = ProcessGradebookUpload.mapLocalAssignmentsToDatabaseAssignments(
      gradebook,
      responses,
    )

    expect(assignmentMap[newAssignment1.id]).toBe(responses[0][0].id)
    expect(assignmentMap[newAssignment2.id]).toBe(responses[1][0].id)
  })
})

describe('ProcessGradebookUpload.populateGradeDataPerSubmission', () => {
  test('rejects an unrecognized or ignored assignment', () => {
    const gradeData = {}
    ProcessGradebookUpload.populateGradeDataPerSubmission(submissionIgnored, 0, [], gradeData)

    expect(_.isEmpty(gradeData)).toBe(true)
  })

  test('does not alter a grade that requires no change', () => {
    const gradeData = {}
    ProcessGradebookUpload.populateGradeDataPerSubmission(submissionOld1NoChange, 0, [], gradeData)

    expect(_.isEmpty(gradeData)).toBe(true)
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

  test('does not error on non-string grades', () => {
    expect(() => {
      ProcessGradebookUpload.populateGradeDataPerSubmission(submissionWithNumericGrade, 0, [], {})
    }).not.toThrow()
    expect(true).toBe(true) // Assertion to indicate the test passed if no error was thrown
  })
})

describe('ProcessGradebookUpload.populateGradeDataPerStudent', () => {
  test('does not modify grade data if student submissions is an empty array', () => {
    const student = {previous_id: 1, submissions: []}
    const gradeData = {}
    const assignmentMap = mapAssignments()
    ProcessGradebookUpload.populateGradeDataPerStudent(student, assignmentMap, gradeData)

    expect(_.isEmpty(gradeData)).toBe(true)
  })

  test.skip('properly populates grade data for a student', () => {
    const student = {
      previous_id: 1,
      submissions: [
        submissionOld1Change,
        submissionOld2Excused,
        submissionNew1Excused,
        submissionNew2Change,
      ],
    }
    const gradeData = {}
    const assignmentMap = mapAssignments()
    ProcessGradebookUpload.populateGradeDataPerStudent(student, assignmentMap, gradeData)

    expect(gradeData[submissionOld1Change.assignment_id][student.previous_id].posted_grade).toBe(
      submissionOld1Change.grade,
    )
    expect(gradeData[submissionOld2Excused.assignment_id][student.previous_id].excuse).toBe(true)
    expect(
      gradeData[assignmentMap[submissionNew1Excused.assignment_id]][student.previous_id].excuse,
    ).toBe(true)
    expect(
      gradeData[assignmentMap[submissionNew2Change.assignment_id]][student.previous_id]
        .posted_grade,
    ).toBe(submissionNew2Change.grade)
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
    const student3 = {
      previous_id: 3,
      submissions: [submissionOld1Excused, submissionOld2Change, submissionNew2Change],
    }
    const gradebook = {
      students: [student1, student2, student3],
      assignments: [oldAssignment1, oldAssignment2, newAssignment1, newAssignment2],
    }
    const responses = [[createAssignmentResponse1], [createAssignmentResponse2]]
    const gradeData = ProcessGradebookUpload.populateGradeData(gradebook, responses)

    expect(gradeData[submissionOld1Change.assignment_id][student1.previous_id].posted_grade).toBe(
      submissionOld1Change.grade,
    )
    expect(gradeData[createAssignmentResponse1.id][student1.previous_id].excuse).toBe(true)
    expect(gradeData[createAssignmentResponse2.id][student1.previous_id].posted_grade).toBe(
      submissionNew2Change.grade,
    )
    expect(gradeData[submissionOld2Excused.assignment_id][student2.previous_id].excuse).toBe(true)
    expect(gradeData[createAssignmentResponse1.id][student2.previous_id].posted_grade).toBe(
      submissionNew2Change.grade,
    )
    expect(gradeData[createAssignmentResponse2.id][student2.previous_id].excuse).toBe(true)
    expect(gradeData[submissionOld1Excused.assignment_id][student3.previous_id].excuse).toBe(true)
    expect(gradeData[submissionOld2Change.assignment_id][student3.previous_id].posted_grade).toBe(
      submissionOld2Change.grade,
    )
    expect(gradeData[createAssignmentResponse2.id][student3.previous_id].posted_grade).toBe(
      submissionNew2Change.grade,
    )
  })
})

describe('ProcessGradebookUpload.submitGradeData', () => {
  beforeEach(() => {
    // Setup fake XMLHttpRequest
    xhr = sinon.useFakeXMLHttpRequest()
    requests = []

    xhr.onCreate = function (request) {
      requests.push(request)
    }

    // Setup fake environment
    fakeENV.setup()
    window.ENV = window.ENV || {}
    window.ENV.bulk_update_path = '/bulk_update_path/url'
  })

  afterEach(() => {
    // Restore fake XMLHttpRequest and environment
    xhr.restore()
    fakeENV.teardown()
  })

  test.skip('properly submits grade data', () => {
    const gradeData = {
      1: {
        1: {posted_grade: '20'},
        2: {excuse: true},
      },
      2: {
        1: {posted_grade: '25'},
        2: {posted_grade: '15'},
      },
      3: {
        1: {excuse: true},
        2: {excuse: true},
      },
    }
    ProcessGradebookUpload.submitGradeData(gradeData)

    expect(requests).toHaveLength(1)
    expect(requests[0].url).toBe('/bulk_update_path/url')
    expect(requests[0].method).toBe('POST')

    const bulkUpdateRequest = JSON.parse(requests[0].requestBody)
    expect(bulkUpdateRequest.grade_data[1][1].posted_grade).toBe(20)
    expect(bulkUpdateRequest.grade_data[1][2].excuse).toBe(true)
    expect(bulkUpdateRequest.grade_data[2][1].posted_grade).toBe(25)
    expect(bulkUpdateRequest.grade_data[2][2].posted_grade).toBe(15)
    expect(bulkUpdateRequest.grade_data[3][1].excuse).toBe(true)
    expect(bulkUpdateRequest.grade_data[3][2].excuse).toBe(true)
  })
})

describe('ProcessGradebookUpload.upload', () => {
  let sandbox

  beforeEach(() => {
    // Setup stubs and fake XMLHttpRequest
    sandbox = sinon.createSandbox()
    sandbox.stub(window, 'alert')
    xhr = sinon.useFakeXMLHttpRequest()
    requests = []

    xhr.onCreate = function (request) {
      requests.push(request)
    }

    goToGradebookStub = sandbox.stub(ProcessGradebookUpload, 'goToGradebook')

    clock = sinon.useFakeTimers()

    // Setup fake environment
    fakeENV.setup()
    window.ENV = window.ENV || {}
    window.ENV.create_assignment_path = '/create_assignment_path/url'
    window.ENV.bulk_update_path = '/bulk_update_path/url'
    window.ENV.bulk_update_override_scores_path = '/bulk_update_override_scores_path/url'
    window.ENV.custom_grade_statuses = [
      {
        id: 1,
        name: 'POTATO',
        color: '#999999',
      },
      {
        id: 2,
        name: 'CARROT',
        color: '#000000',
      },
    ]
  })

  afterEach(() => {
    // Restore stubs and fake XMLHttpRequest
    xhr.restore()
    ProcessGradebookUpload.goToGradebook.restore()
    clock.restore()
    fakeENV.teardown()
    sandbox.restore()
  })

  test('sends no data to server if given null', () => {
    ProcessGradebookUpload.upload(null)
    expect(requests).toHaveLength(0)
  })

  test('sends no data to server if given an empty object', () => {
    ProcessGradebookUpload.upload({})
    expect(requests).toHaveLength(0)
  })

  test('sends no data to server if given a single existing assignment with no submissions', () => {
    const student = {previous_id: 1, submissions: []}
    const gradebook = {students: [student], assignments: [oldAssignment1]}
    ProcessGradebookUpload.upload(gradebook)

    expect(requests).toHaveLength(0)
  })

  test('sends no data to server if given a single existing assignment that requires no change', () => {
    const student = {previous_id: 1, submissions: [submissionOld1NoChange]}
    const gradebook = {students: [student], assignments: [oldAssignment1]}
    ProcessGradebookUpload.upload(gradebook)

    expect(requests).toHaveLength(0)
  })

  test('handles a grade change to a single existing assignment', () => {
    const student = {previous_id: 1, submissions: [submissionOld1Change]}
    const gradebook = {students: [student], assignments: [oldAssignment1]}
    ProcessGradebookUpload.upload(gradebook)
    clock.tick(1)

    expect(requests).toHaveLength(1)
    expect(requests[0].url).toBe('/bulk_update_path/url')
    expect(requests[0].method).toBe('POST')

    const bulkUpdateRequest = JSON.parse(requests[0].requestBody)
    expect(bulkUpdateRequest.grade_data[oldAssignment1.id][student.previous_id].posted_grade).toBe(
      submissionOld1Change.grade,
    )

    requests[0].respond(200, {}, JSON.stringify(progressCompleted))
    clock.tick(3)

    expect(goToGradebookStub.called).toBe(true)
  })

  test('handles a change to excused to a single existing assignment', () => {
    const student = {previous_id: 1, submissions: [submissionOld1Excused]}
    const gradebook = {students: [student], assignments: [oldAssignment1]}
    ProcessGradebookUpload.upload(gradebook)
    clock.tick(1)

    expect(requests).toHaveLength(1)
    expect(requests[0].url).toBe('/bulk_update_path/url')
    expect(requests[0].method).toBe('POST')

    const bulkUpdateRequest = JSON.parse(requests[0].requestBody)
    expect(bulkUpdateRequest.grade_data[oldAssignment1.id][student.previous_id].excuse).toBe(true)

    requests[0].respond(200, {}, JSON.stringify(progressCompleted))
    clock.tick(3)

    expect(goToGradebookStub.called).toBe(true)
  })

  test.skip('handles multiple students changing a single existing assignment', () => {
    const student1 = {previous_id: 1, submissions: [submissionOld1Change]}
    const student2 = {previous_id: 2, submissions: [submissionOld1Excused]}
    const gradebook = {students: [student1, student2], assignments: [oldAssignment1]}
    ProcessGradebookUpload.upload(gradebook)
    clock.tick(1)

    expect(requests).toHaveLength(1)
    expect(requests[0].url).toBe('/bulk_update_path/url')
    expect(requests[0].method).toBe('POST')

    const bulkUpdateRequest = JSON.parse(requests[0].requestBody)
    expect(bulkUpdateRequest.grade_data[oldAssignment1.id][student1.previous_id].posted_grade).toBe(
      submissionOld1Change.grade,
    )
    expect(bulkUpdateRequest.grade_data[oldAssignment1.id][student2.previous_id].excuse).toBe(true)

    requests[0].respond(200, {}, JSON.stringify(progressCompleted))
    clock.tick(3)

    expect(goToGradebookStub.called).toBe(true)
  })

  test.skip('handles multiple students changing multiple existing assignments', () => {
    const student1 = {previous_id: 1, submissions: [submissionOld1Change, submissionOld2Excused]}
    const student2 = {previous_id: 2, submissions: [submissionOld1Excused, submissionOld2Change]}
    const gradebook = {
      students: [student1, student2],
      assignments: [oldAssignment1, oldAssignment2],
    }
    ProcessGradebookUpload.upload(gradebook)
    clock.tick(1)

    expect(requests).toHaveLength(1)
    expect(requests[0].url).toBe('/bulk_update_path/url')
    expect(requests[0].method).toBe('POST')

    const bulkUpdateRequest = JSON.parse(requests[0].requestBody)
    expect(bulkUpdateRequest.grade_data[oldAssignment1.id][student1.previous_id].posted_grade).toBe(
      submissionOld1Change.grade,
    )
    expect(bulkUpdateRequest.grade_data[oldAssignment1.id][student2.previous_id].excuse).toBe(true)
    expect(bulkUpdateRequest.grade_data[oldAssignment2.id][student1.previous_id].excuse).toBe(true)
    expect(bulkUpdateRequest.grade_data[oldAssignment2.id][student2.previous_id].posted_grade).toBe(
      submissionOld2Change.grade,
    )

    requests[0].respond(200, {}, JSON.stringify(progressCompleted))
    clock.tick(3)

    expect(goToGradebookStub.called).toBe(true)
  })

  test('handles a creation of a new assignment with no submissions', () => {
    const student = {previous_id: 1, submissions: []}
    const gradebook = {students: [student], assignments: [newAssignment1]}
    ProcessGradebookUpload.upload(gradebook)
    clock.tick(1)

    expect(requests).toHaveLength(1)
    expect(requests[0].url).toBe('/create_assignment_path/url')
    expect(requests[0].method).toBe('POST')

    const createAssignmentRequest = JSON.parse(requests[0].requestBody)
    equalAssignment(createAssignmentRequest.assignment, newAssignment1)

    requests[0].respond(200, {}, JSON.stringify(createAssignmentResponse1))
    clock.tick(3)

    expect(goToGradebookStub.called).toBe(true)
  })

  test('handles the creation of several new assignments with no submissions', () => {
    const student = {previous_id: 1, submissions: []}
    const gradebook = {students: [student], assignments: [newAssignment1, newAssignment2]}
    ProcessGradebookUpload.upload(gradebook)
    clock.tick(1)

    expect(requests).toHaveLength(2)

    expect(requests[0].url).toBe('/create_assignment_path/url')
    expect(requests[0].method).toBe('POST')

    const createAssignmentRequest1 = JSON.parse(requests[0].requestBody)
    equalAssignment(createAssignmentRequest1.assignment, newAssignment1)

    requests[0].respond(200, {}, JSON.stringify(createAssignmentResponse1))
    clock.tick(3)

    expect(requests[1].url).toBe('/create_assignment_path/url')
    expect(requests[1].method).toBe('POST')

    const createAssignmentRequest2 = JSON.parse(requests[1].requestBody)
    equalAssignment(createAssignmentRequest2.assignment, newAssignment2)

    requests[1].respond(200, {}, JSON.stringify(createAssignmentResponse2))
    clock.tick(3)

    expect(goToGradebookStub.called).toBe(true)
  })

  test('handles a creation of a new assignment with no grade change', () => {
    const student = {previous_id: 1, submissions: [submissionNew1NoChange]}
    const gradebook = {students: [student], assignments: [newAssignment1]}
    ProcessGradebookUpload.upload(gradebook)
    clock.tick(1)

    expect(requests).toHaveLength(1)
    expect(requests[0].url).toBe('/create_assignment_path/url')
    expect(requests[0].method).toBe('POST')

    const createAssignmentRequest = JSON.parse(requests[0].requestBody)
    equalAssignment(createAssignmentRequest.assignment, newAssignment1)

    requests[0].respond(200, {}, JSON.stringify(createAssignmentResponse1))
    clock.tick(3)

    expect(goToGradebookStub.called).toBe(true)
  })

  test('handles creation of a new assignment with a grade change', () => {
    const student = {previous_id: 1, submissions: [submissionNew1Change]}
    const gradebook = {students: [student], assignments: [newAssignment1]}
    ProcessGradebookUpload.upload(gradebook)
    clock.tick(1)

    expect(requests).toHaveLength(1)
    expect(requests[0].url).toBe('/create_assignment_path/url')
    expect(requests[0].method).toBe('POST')

    const createAssignmentRequest = JSON.parse(requests[0].requestBody)
    equalAssignment(createAssignmentRequest.assignment, newAssignment1)

    requests[0].respond(200, {}, JSON.stringify(createAssignmentResponse1))
    clock.tick(3)

    expect(requests).toHaveLength(2)
    expect(requests[1].url).toBe('/bulk_update_path/url')
    expect(requests[1].method).toBe('POST')

    const bulkUpdateRequest = JSON.parse(requests[1].requestBody)
    expect(
      bulkUpdateRequest.grade_data[createAssignmentResponse1.id][student.previous_id].posted_grade,
    ).toBe(submissionNew1Change.grade)

    requests[1].respond(200, {}, JSON.stringify(progressCompleted))
    clock.tick(3)

    expect(goToGradebookStub.called).toBe(true)
  })

  test('handles creation of a new assignment with a change to excused', () => {
    const student = {previous_id: 1, submissions: [submissionNew1Excused]}
    const gradebook = {students: [student], assignments: [newAssignment1]}
    ProcessGradebookUpload.upload(gradebook)
    clock.tick(1)

    expect(requests).toHaveLength(1)
    expect(requests[0].url).toBe('/create_assignment_path/url')
    expect(requests[0].method).toBe('POST')

    const createAssignmentRequest = JSON.parse(requests[0].requestBody)
    equalAssignment(createAssignmentRequest.assignment, newAssignment1)

    requests[0].respond(200, {}, JSON.stringify(createAssignmentResponse1))
    clock.tick(3)

    expect(requests).toHaveLength(2)
    expect(requests[1].url).toBe('/bulk_update_path/url')
    expect(requests[1].method).toBe('POST')

    const bulkUpdateRequest = JSON.parse(requests[1].requestBody)
    expect(
      bulkUpdateRequest.grade_data[createAssignmentResponse1.id][student.previous_id].excuse,
    ).toBe(true)

    requests[1].respond(200, {}, JSON.stringify(progressCompleted))
    clock.tick(3)

    expect(goToGradebookStub.called).toBe(true)
  })

  test('handles multiple students changing a single new assignment', () => {
    const student1 = {previous_id: 1, submissions: [submissionNew1Change]}
    const student2 = {previous_id: 2, submissions: [submissionNew1Excused]}
    const gradebook = {students: [student1, student2], assignments: [newAssignment1]}
    ProcessGradebookUpload.upload(gradebook)
    clock.tick(1)

    expect(requests).toHaveLength(1)
    expect(requests[0].url).toBe('/create_assignment_path/url')
    expect(requests[0].method).toBe('POST')

    const createAssignmentRequest = JSON.parse(requests[0].requestBody)
    equalAssignment(createAssignmentRequest.assignment, newAssignment1)

    requests[0].respond(200, {}, JSON.stringify(createAssignmentResponse1))
    clock.tick(3)

    expect(requests).toHaveLength(2)
    expect(requests[1].url).toBe('/bulk_update_path/url')
    expect(requests[1].method).toBe('POST')

    const bulkUpdateRequest = JSON.parse(requests[1].requestBody)
    expect(
      bulkUpdateRequest.grade_data[createAssignmentResponse1.id][student1.previous_id].posted_grade,
    ).toBe(submissionNew1Change.grade)
    expect(
      bulkUpdateRequest.grade_data[createAssignmentResponse1.id][student2.previous_id].excuse,
    ).toBe(true)

    requests[1].respond(200, {}, JSON.stringify(progressCompleted))
    clock.tick(3)

    expect(goToGradebookStub.called).toBe(true)
  })

  test.skip('handles multiple students changing multiple new and existing assignments', () => {
    const student1 = {
      previous_id: 1,
      submissions: [submissionOld1Change, submissionNew1Excused, submissionNew2Change],
    }
    const student2 = {
      previous_id: 2,
      submissions: [submissionOld2Excused, submissionNew1Change, submissionNew2Excused],
    }
    const student3 = {}
    const gradebook = {
      students: [student1, student2],
      assignments: [oldAssignment1, oldAssignment2, newAssignment1, newAssignment2],
    }
    ProcessGradebookUpload.upload(gradebook)
    clock.tick(1)

    expect(requests).toHaveLength(2)
    expect(requests[0].url).toBe('/create_assignment_path/url')
    expect(requests[0].method).toBe('POST')

    const createAssignmentRequest1 = JSON.parse(requests[0].requestBody)
    equalAssignment(createAssignmentRequest1.assignment, newAssignment1)

    requests[0].respond(200, {}, JSON.stringify(createAssignmentResponse1))
    clock.tick(3)

    expect(requests).toHaveLength(2)
    expect(requests[1].url).toBe('/create_assignment_path/url')
    expect(requests[1].method).toBe('POST')

    const createAssignmentRequest2 = JSON.parse(requests[1].requestBody)
    equalAssignment(createAssignmentRequest2.assignment, newAssignment2)

    requests[1].respond(200, {}, JSON.stringify(createAssignmentResponse2))
    clock.tick(3)

    expect(requests).toHaveLength(3)
    expect(requests[2].url).toBe('/bulk_update_path/url')
    expect(requests[2].method).toBe('POST')

    const bulkUpdateRequest = JSON.parse(requests[2].requestBody)
    expect(bulkUpdateRequest.grade_data[oldAssignment1.id][student1.previous_id].posted_grade).toBe(
      submissionOld1Change.grade,
    )
    expect(bulkUpdateRequest.grade_data[oldAssignment1.id][student2.previous_id].excuse).toBe(true)
    expect(bulkUpdateRequest.grade_data[oldAssignment2.id][student1.previous_id].excuse).toBe(true)
    expect(bulkUpdateRequest.grade_data[oldAssignment2.id][student2.previous_id].posted_grade).toBe(
      submissionOld2Change.grade,
    )
    expect(
      bulkUpdateRequest.grade_data[createAssignmentResponse1.id][student1.previous_id].excuse,
    ).toBe(true)
    expect(
      bulkUpdateRequest.grade_data[createAssignmentResponse1.id][student2.previous_id].posted_grade,
    ).toBe(submissionNew1Change.grade)
    expect(
      bulkUpdateRequest.grade_data[createAssignmentResponse2.id][student1.previous_id].posted_grade,
    ).toBe(submissionNew2Change.grade)
    expect(
      bulkUpdateRequest.grade_data[createAssignmentResponse2.id][student2.previous_id].excuse,
    ).toBe(true)
    expect(
      bulkUpdateRequest.grade_data[createAssignmentResponse2.id][student3.previous_id].posted_grade,
    ).toBe(submissionNew2Change.grade)

    requests[2].respond(200, {}, JSON.stringify(progressCompleted))
    clock.tick(3)

    expect(goToGradebookStub.called).toBe(true)
  })

  test('calls uploadCustomColumnData if custom_columns is non-empty', () => {
    const uploadCustomColumnDataStub = sandbox.stub(
      ProcessGradebookUpload,
      'uploadCustomColumnData',
    )
    const student1 = {
      previous_id: 1,
      submissions: [submissionOld1Change, submissionNew1Excused, submissionNew2Change],
    }
    const gradebook = {
      students: [student1],
      assignments: [oldAssignment1, oldAssignment2, newAssignment1, newAssignment2],
      custom_columns: [customColumn1],
    }
    ProcessGradebookUpload.upload(gradebook)

    expect(uploadCustomColumnDataStub.calledOnce).toBe(true)

    uploadCustomColumnDataStub.restore()
  })

  test('does not call uploadCustomColumnData if custom_columns is empty', () => {
    const uploadCustomColumnDataStub = sandbox.stub(
      ProcessGradebookUpload,
      'uploadCustomColumnData',
    )
    const student1 = {
      previous_id: 1,
      submissions: [submissionOld1Change, submissionNew1Excused, submissionNew2Change],
    }
    const gradebook = {
      students: [student1],
      assignments: [oldAssignment1, oldAssignment2, newAssignment1, newAssignment2],
      custom_columns: [],
    }
    ProcessGradebookUpload.upload(gradebook)

    expect(uploadCustomColumnDataStub.notCalled).toBe(true)

    uploadCustomColumnDataStub.restore()
  })

  test('creates requests for override score changes if an update URL is set', () => {
    const gradebook = {
      assignments: [],
      custom_columns: [],
      students: [
        {
          id: '1',
          override_scores: [
            {
              current_score: '75',
              new_score: '80',
            },
          ],
          submissions: [],
        },
      ],
    }
    ProcessGradebookUpload.upload(gradebook)
    clock.tick(1)

    expect(requests).toHaveLength(1)
  })

  test('creates requests for override status changes', () => {
    const gradebook = {
      assignments: [],
      custom_columns: [],
      students: [
        {
          id: '1',
          override_scores: [],
          override_statuses: [
            {
              current_grade_status: 'POTATO',
              new_grade_status: 'CARROT',
              grading_period_id: null,
              student_id: '1',
            },
          ],
          submissions: [],
        },
      ],
    }
    ProcessGradebookUpload.upload(gradebook)

    expect(requests).toHaveLength(1)
  })

  test('creates requests for override status changes with multiple grading periods', () => {
    const gradebook = {
      assignments: [],
      custom_columns: [],
      students: [
        {
          id: '1',
          override_scores: [],
          override_statuses: [
            {
              current_grade_status: 'POTATO',
              new_grade_status: 'CARROT',
              grading_period_id: null,
              student_id: '1',
            },
            {
              current_grade_status: 'POTATO',
              new_grade_status: 'CARROT',
              grading_period_id: '1',
              student_id: '1',
            },
            {
              current_grade_status: 'POTATO',
              new_grade_status: 'CARROT',
              grading_period_id: '2',
              student_id: '1',
            },
          ],
          submissions: [],
        },
      ],
    }
    ProcessGradebookUpload.upload(gradebook)

    expect(requests).toHaveLength(3)
  })

  test('creates requests for override score and status changes for multiple grading periods', () => {
    const gradebook = {
      assignments: [],
      custom_columns: [],
      students: [
        {
          id: '1',
          override_scores: [
            {
              current_score: '75',
              new_score: '80',
            },
            {
              current_score: '80',
              new_score: '85',
              grading_period_id: '1',
            },
          ],
          override_statuses: [
            {
              current_grade_status: 'POTATO',
              new_grade_status: 'CARROT',
              grading_period_id: null,
              student_id: '1',
            },
            {
              current_grade_status: 'CARROT',
              new_grade_status: 'POTATO',
              grading_period_id: '1',
              student_id: '1',
            },
          ],
          submissions: [],
        },
      ],
    }
    ProcessGradebookUpload.upload(gradebook)

    expect(requests).toHaveLength(2)
    requests.forEach(request => {
      const body = JSON.parse(request.requestBody)
      if (body.grading_period_id === '1') {
        expect(body.override_scores[0].override_score).toBe('85')
        expect(body.override_scores[0].override_status_id).toBe(1)
      } else {
        expect(body.override_scores[0].override_score).toBe('80')
        expect(body.override_scores[0].override_status_id).toBe(2)
      }
    })
  })

  test('ignores override score changes if no update URL is set', () => {
    const gradebook = {
      assignments: [],
      custom_columns: [],
      students: [
        {
          id: '1',
          override_scores: [
            {
              current_score: '75',
              new_score: '80',
            },
          ],
          submissions: [],
        },
      ],
    }
    delete window.ENV.bulk_update_override_scores_path
    ProcessGradebookUpload.upload(gradebook)

    expect(requests).toHaveLength(0)
  })

  test('shows an alert if any bulk data is being uploaded', () => {
    const gradebook = {
      assignments: [
        {
          title: 'a new assignment',
          id: -1,
          points_possible: 10,
        },
        {
          title: 'an even newer assignment',
          id: -2,
          points_possible: 20,
        },
      ],
      students: [
        {
          id: '1',
          submissions: [{assignment_id: -1, grade: '10', original_grade: '9'}],
        },
      ],
    }

    ProcessGradebookUpload.upload(gradebook)
    clock.tick(1)

    // Respond to assignment creation requests
    requests.forEach((request, idx) => {
      request.respond(200, {}, JSON.stringify({id: idx + 1000}))
    })
    clock.tick(3)

    // Respond to grade upload requests
    requests
      .filter(request => request.url === '/bulk_update_path/url')
      .forEach(request => {
        request.respond(200, {}, JSON.stringify(progressQueued))
      })
    clock.tick(3)

    expect(window.alert.callCount).toBe(1)
  })

  test('does not show an alert if the only changes involve creating new assignments', () => {
    const gradebook = {
      assignments: [
        {
          title: 'a new assignment',
          id: -1,
          points_possible: 10,
        },
        {
          title: 'an even newer assignment',
          id: -2,
          points_possible: 20,
        },
      ],
      students: [
        {
          id: '1',
          submissions: [],
        },
      ],
    }
    ProcessGradebookUpload.upload(gradebook)

    expect(window.alert.callCount).toBe(0)
  })

  test('does not redirect to gradebook until all requests have completed', () => {
    const gradebook = {
      assignments: [newAssignment1, oldAssignment1],
      students: [
        {
          id: 1,
          submissions: [submissionOld1Change, submissionNew1Change],
          override_scores: [{current_score: '70', new_score: '75'}],
        },
      ],
    }
    ProcessGradebookUpload.upload(gradebook)
    clock.tick(1)

    expect(goToGradebookStub.callCount).toBe(0)

    // Respond to assignment creation requests
    requests
      .filter(request => request.url === '/create_assignment_path/url')
      .forEach(request => {
        request.respond(200, {}, JSON.stringify({id: 1000}))
      })
    clock.tick(3)

    // Respond to override score requests
    requests
      .filter(request => request.url === '/bulk_update_override_scores_path/url')
      .forEach(request => {
        request.respond(200, {}, JSON.stringify(progressQueued))
      })
    clock.tick(3)

    // At this point, goToGradebook should not be called yet
    expect(goToGradebookStub.callCount).toBe(0)

    // Respond to grade upload requests
    requests
      .filter(request => request.url === '/bulk_update_path/url')
      .forEach(request => {
        request.respond(200, {}, JSON.stringify(progressQueued))
      })
    clock.tick(3)

    // Now, goToGradebook should be called
    expect(goToGradebookStub.callCount).toBe(1)
  })
})

describe.skip('ProcessGradebookUpload.parseCustomColumnData', () => {
  test('correctly parses data for one student', () => {
    const customColumnData = {
      10: [
        {
          new_content: 'first content',
          column_id: 1,
        },
        {
          new_content: 'second content',
          column_id: 3,
        },
      ],
    }

    const data = ProcessGradebookUpload.parseCustomColumnData(customColumnData)
    expect(data).toHaveLength(2)
    expect(data[0].user_id).toBe(10)
    expect(data[0].column_id).toBe(1)
    expect(data[0].content).toBe('first content')
    expect(data[1].user_id).toBe(10)
    expect(data[1].column_id).toBe(3)
    expect(data[1].content).toBe('second content')
  })

  test('correctly parses data for multiple students', () => {
    const customColumnData = {
      10: [
        {
          new_content: 'first content',
          column_id: 1,
        },
      ],
      1: [
        {
          new_content: 'second content',
          column_id: 2,
        },
      ],
    }

    const data = ProcessGradebookUpload.parseCustomColumnData(customColumnData)
    expect(data).toHaveLength(2)
    expect(data[0].user_id).toBe(1)
    expect(data[0].column_id).toBe(2)
    expect(data[0].content).toBe('second content')
    expect(data[1].user_id).toBe(10)
    expect(data[1].column_id).toBe(1)
    expect(data[1].content).toBe('first content')
  })
})

describe('ProcessGradebookUpload.submitCustomColumnData', () => {
  let sandbox

  beforeEach(() => {
    // Setup fake XMLHttpRequest
    sandbox = sinon.createSandbox()
    sandbox.stub(window, 'alert')
    xhr = sinon.useFakeXMLHttpRequest()
    requests = []

    xhr.onCreate = function (request) {
      requests.push(request)
    }

    // Setup fake environment
    fakeENV.setup()
    window.ENV = window.ENV || {}
    window.ENV.bulk_update_custom_columns_path = '/bulk_update_custom_columns_path/url'
  })

  afterEach(() => {
    // Restore fake XMLHttpRequest and environment
    xhr.restore()
    fakeENV.teardown()
    sandbox.restore()
  })

  test('correctly submits custom column data', () => {
    const gradeData = [
      {
        column_id: 1,
        user_id: 2,
        content: 'test content',
      },
      {
        column_id: 3,
        user_id: 4,
        content: 'test content 2',
      },
    ]

    ProcessGradebookUpload.submitCustomColumnData(gradeData)

    expect(requests).toHaveLength(1)
    expect(requests[0].url).toBe('/bulk_update_custom_columns_path/url')
    expect(requests[0].method).toBe('PUT')

    const bulkUpdateRequest = JSON.parse(requests[0].requestBody)
    expect(bulkUpdateRequest.column_data[0].column_id).toBe(1)
    expect(bulkUpdateRequest.column_data[0].user_id).toBe(2)
    expect(bulkUpdateRequest.column_data[0].content).toBe('test content')
    expect(bulkUpdateRequest.column_data[1].column_id).toBe(3)
    expect(bulkUpdateRequest.column_data[1].user_id).toBe(4)
    expect(bulkUpdateRequest.column_data[1].content).toBe('test content 2')
  })
})

describe('ProcessGradebookUpload.createOverrideUpdateRequests', () => {
  beforeEach(() => {
    // Setup fake XMLHttpRequest
    xhr = sinon.useFakeXMLHttpRequest()
    requests = []

    xhr.onCreate = function (request) {
      requests.push(request)
    }

    // Setup fake environment
    fakeENV.setup({bulk_update_override_scores_path: '/bulk_update_override_scores_path'})
  })

  afterEach(() => {
    // Restore fake XMLHttpRequest and environment
    xhr.restore()
    fakeENV.teardown()
  })

  const studentWithCourseGradeUpdate = {
    id: '1',
    override_scores: [
      {
        current_score: '80',
        new_score: '90',
      },
    ],
  }
  const studentWithGradingPeriodUpdate = {
    id: '2',
    override_scores: [
      {
        current_score: '80',
        grading_period_id: '1',
        new_score: '90',
      },
    ],
  }
  const studentWithMultipleUpdates = {
    id: '3',
    override_scores: [
      {
        current_score: '80',
        grading_period_id: '1',
        new_score: '90',
      },
      {
        current_score: '80',
        grading_period_id: '2',
        new_score: '90',
      },
      {
        current_score: '40',
        new_score: '50',
      },
    ],
  }
  const studentWithNoActualChanges = {
    id: '999',
    override_scores: [
      {
        current_score: '80',
        new_score: '80',
      },
      {
        current_score: '70',
        grading_period_id: '1',
        new_score: '70.0',
      },
      {
        current_score: '',
        grading_period_id: '2',
        new_score: null,
      },
      {
        current_score: 'null',
        grading_period_id: '3',
        new_score: null,
      },
    ],
  }

  test.skip('creates an update request for each grading period/course with changed scores', () => {
    const gradebook = {
      students: [studentWithMultipleUpdates],
    }

    ProcessGradebookUpload.createOverrideUpdateRequests(gradebook)
    expect(requests).toHaveLength(3)

    const urls = requests.map(request => request.url)
    expect(urls[0]).toBe('/bulk_update_override_scores_path/url')
  })

  test('includes the grading_period_id in the parameters for updates for that grading period', () => {
    const gradebook = {
      students: [studentWithGradingPeriodUpdate],
    }
    ProcessGradebookUpload.createOverrideUpdateRequests(gradebook)

    const body = JSON.parse(requests[0].requestBody)
    expect(body.grading_period_id).toBe('1')
  })

  test.skip('does not include grading_period_id if updating course scores', () => {
    const gradebook = {
      students: [studentWithCourseGradeUpdate],
    }
    ProcessGradebookUpload.createOverrideUpdateRequests(gradebook)

    const body = JSON.parse(requests[0].requestBody)
    expect(body.grading_period_id).toBe(null)
  })

  test('only includes override score updates containing changes to the scores', () => {
    const gradebook = {
      students: [studentWithNoActualChanges],
    }
    ProcessGradebookUpload.createOverrideUpdateRequests(gradebook)

    expect(requests).toHaveLength(0)
  })

  test('includes the new score and student ID in the body of each request', () => {
    const gradebook = {
      students: [studentWithGradingPeriodUpdate],
    }
    ProcessGradebookUpload.createOverrideUpdateRequests(gradebook)

    const body = JSON.parse(requests[0].requestBody)
    expect(body.override_scores[0].override_score).toBe('90')
    expect(body.override_scores[0].student_id).toBe('2')
  })
})
