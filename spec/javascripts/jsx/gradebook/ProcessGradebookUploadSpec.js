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

import ProcessGradebookUpload from 'ui/features/gradebook_uploads/jquery/process_gradebook_upload'
import fakeENV from 'helpers/fakeENV'
import '@canvas/datetime'

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
  equal(assignment1.name, assignment2.title)
  equal(assignment1.points_possible, assignment2.points_possible)
  equal(assignment1.published, assignment2.published)
}

QUnit.module('ProcessGradebookUpload.getNewAssignmentsFromGradebook')

test('returns an empty array if the gradebook given has a single assignment with no id', () => {
  const gradebook = {assignments: [{key: 'value'}]}
  const assignments = ProcessGradebookUpload.getNewAssignmentsFromGradebook(gradebook)

  equal(assignments.length, 0)
})

test('returns an empty array if the gradebook given has a single assignment with a null id', () => {
  const gradebook = {assignments: [{id: null, key: 'value'}]}
  const assignments = ProcessGradebookUpload.getNewAssignmentsFromGradebook(gradebook)

  equal(assignments.length, 0)
})

test('returns an empty array if the gradebook given has a single assignment with positive id', () => {
  const gradebook = {assignments: [{id: 1}]}
  const assignments = ProcessGradebookUpload.getNewAssignmentsFromGradebook(gradebook)

  equal(assignments.length, 0)
})

test('returns an array with one assignment if gradebook given has a single assignment with zero id', () => {
  const gradebook = {assignments: [{id: 0}]}
  const assignments = ProcessGradebookUpload.getNewAssignmentsFromGradebook(gradebook)

  equal(assignments.length, 1)
  equal(assignments[0].id, 0)
})

test('returns an array with one assignment if the gradebook given has a single assignment with negative id', () => {
  const gradebook = {assignments: [{id: -1}]}
  const assignments = ProcessGradebookUpload.getNewAssignmentsFromGradebook(gradebook)

  equal(assignments.length, 1)
  equal(assignments[0].id, -1)
})

test('returns an array with only the assignments with non positive ids if the gradebook given has all ids', () => {
  const gradebook = {assignments: [{id: -1}, {id: 0}, {id: 1}]}
  const assignments = ProcessGradebookUpload.getNewAssignmentsFromGradebook(gradebook)

  equal(assignments.length, 2)
  ok(assignments[0].id < 1)
  ok(assignments[1].id < 1)
})

QUnit.module('ProcessGradebookUpload.createIndividualAssignment', {
  setup() {
    xhr = sinon.useFakeXMLHttpRequest()
    requests = []

    xhr.onCreate = function (request) {
      requests.push(request)
    }

    fakeENV.setup()
    ENV.create_assignment_path = '/create_assignment_path/url'
  },
  teardown() {
    xhr.restore()

    fakeENV.teardown()
  },
})

test('properly creates a new assignment', () => {
  ProcessGradebookUpload.createIndividualAssignment(oldAssignment1)

  equal(requests.length, 1)
  equal(requests[0].url, '/create_assignment_path/url')
  equal(requests[0].method, 'POST')

  const createAssignmentRequest = JSON.parse(requests[0].requestBody)
  equalAssignment(createAssignmentRequest.assignment, oldAssignment1)
})

QUnit.module('ProcessGradebookUpload.createAssignments', {
  setup() {
    xhr = sinon.useFakeXMLHttpRequest()
    requests = []

    xhr.onCreate = function (request) {
      requests.push(request)
    }

    fakeENV.setup()
    ENV.create_assignment_path = '/create_assignment_path/url'
  },
  teardown() {
    xhr.restore()
    fakeENV.teardown()
  },
})

test('sends no data to server and returns an empty array if given no assignments', () => {
  const gradebook = {assignments: []}
  const responses = ProcessGradebookUpload.createAssignments(gradebook)

  equal(requests.length, 0)
  equal(responses.length, 0)
})

test('properly filters and creates multiple assignments', () => {
  const gradebook = {
    assignments: [oldAssignment1, oldAssignment2, newAssignment1, newAssignment2],
  }
  ProcessGradebookUpload.createAssignments(gradebook)

  equal(requests.length, 2)

  equal(requests[0].url, '/create_assignment_path/url')
  equal(requests[0].method, 'POST')

  const createAssignmentRequest1 = JSON.parse(requests[0].requestBody)
  equalAssignment(createAssignmentRequest1.assignment, newAssignment1)

  equal(requests[1].url, '/create_assignment_path/url')
  equal(requests[1].method, 'POST')

  const createAssignmentRequest2 = JSON.parse(requests[1].requestBody)
  equalAssignment(createAssignmentRequest2.assignment, newAssignment2)
})

test('sends calculate_grades: false as an argument when creating assignments', () => {
  const gradebook = {
    assignments: [newAssignment1],
  }
  ProcessGradebookUpload.createAssignments(gradebook)

  const createAssignmentRequest = JSON.parse(requests[0].requestBody)
  strictEqual(createAssignmentRequest.calculate_grades, false)
})

QUnit.module('ProcessGradebookUpload.mapLocalAssignmentsToDatabaseAssignments')

test('properly pairs if length is 1 and responses is not an array of arrays', () => {
  const gradebook = {assignments: [newAssignment1]}
  const responses = [{id: 3}]
  const assignmentMap = ProcessGradebookUpload.mapLocalAssignmentsToDatabaseAssignments(
    gradebook,
    responses
  )

  equal(assignmentMap[newAssignment1.id], responses[0].id)
})

test('properly pairs if length is not 1 and responses is an array of arrays', () => {
  const gradebook = {assignments: [newAssignment1, newAssignment2]}
  const responses = [[{id: 3}], [{id: 4}]]
  const assignmentMap = ProcessGradebookUpload.mapLocalAssignmentsToDatabaseAssignments(
    gradebook,
    responses
  )

  equal(assignmentMap[newAssignment1.id], responses[0][0].id)
  equal(assignmentMap[newAssignment2.id], responses[1][0].id)
})

test('does not attempt to pair assignments that do not have a negative id', () => {
  const gradebook = {assignments: [newAssignment1, oldAssignment1, oldAssignment2, newAssignment2]}
  const responses = [[{id: 3}], [{id: 4}]]
  const assignmentMap = ProcessGradebookUpload.mapLocalAssignmentsToDatabaseAssignments(
    gradebook,
    responses
  )

  equal(assignmentMap[newAssignment1.id], responses[0][0].id)
  equal(assignmentMap[newAssignment2.id], responses[1][0].id)
})

QUnit.module('ProcessGradebookUpload.populateGradeDataPerSubmission')

test('rejects an unrecognized or ignored assignment', () => {
  const gradeData = {}
  ProcessGradebookUpload.populateGradeDataPerSubmission(submissionIgnored, 0, [], gradeData)

  ok(_.isEmpty(gradeData))
})

test('does not alter a grade that requires no change', () => {
  const gradeData = {}
  ProcessGradebookUpload.populateGradeDataPerSubmission(submissionOld1NoChange, 0, [], gradeData)

  ok(_.isEmpty(gradeData))
})

test('alters a grade on a new assignment', () => {
  const gradeData = {}
  const assignmentMap = mapAssignments()
  ProcessGradebookUpload.populateGradeDataPerSubmission(
    submissionNew1Change,
    0,
    assignmentMap,
    gradeData
  )

  equal(
    gradeData[assignmentMap[submissionNew1Change.assignment_id]][0].posted_grade,
    submissionNew1Change.grade
  )
})

test('alters a grade to excused on a new assignment if "EX" is supplied', () => {
  const gradeData = {}
  const assignmentMap = mapAssignments()
  ProcessGradebookUpload.populateGradeDataPerSubmission(
    submissionNew1Excused,
    0,
    assignmentMap,
    gradeData
  )

  equal(gradeData[assignmentMap[submissionNew1Excused.assignment_id]][0].excuse, true)
})

test('alters a grade to excused on a new assignment if "Excused" is supplied', () => {
  const gradeData = {}
  const assignmentMap = mapAssignments()
  ProcessGradebookUpload.populateGradeDataPerSubmission(
    submissionNew1VerboselyExcused,
    0,
    assignmentMap,
    gradeData
  )

  equal(gradeData[assignmentMap[submissionNew1Excused.assignment_id]][0].excuse, true)
})

test('alters a grade on an existing assignment', () => {
  const gradeData = {}
  ProcessGradebookUpload.populateGradeDataPerSubmission(submissionOld1Change, 0, [], gradeData)

  equal(gradeData[submissionOld1Change.assignment_id][0].posted_grade, submissionOld1Change.grade)
})

test('alters a grade to excused on an existing assignment', () => {
  const gradeData = {}
  ProcessGradebookUpload.populateGradeDataPerSubmission(submissionOld1Excused, 0, [], gradeData)

  equal(gradeData[submissionOld1Excused.assignment_id][0].excuse, true)
})

test('does not error on non-string grades', () => {
  ProcessGradebookUpload.populateGradeDataPerSubmission(submissionWithNumericGrade, 0, [], {})
  ok(true, 'Previous line did not cause error')
})

QUnit.module('ProcessGradebookUpload.populateGradeDataPerStudent')

test('does not modify grade data if student submissions is an empty array', () => {
  const student = {previous_id: 1, submissions: []}
  const gradeData = {}
  const assignmentMap = mapAssignments()
  ProcessGradebookUpload.populateGradeDataPerStudent(student, assignmentMap, gradeData)

  ok(_.isEmpty(gradeData))
})

test('properly populates grade data for a student', () => {
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

  equal(
    gradeData[submissionOld1Change.assignment_id][student.previous_id].posted_grade,
    submissionOld1Change.grade
  )
  equal(gradeData[submissionOld2Excused.assignment_id][student.previous_id].excuse, true)
  equal(
    gradeData[assignmentMap[submissionNew1Excused.assignment_id]][student.previous_id].excuse,
    true
  )
  equal(
    gradeData[assignmentMap[submissionNew2Change.assignment_id]][student.previous_id].posted_grade,
    submissionNew2Change.grade
  )
})

QUnit.module('ProcessGradebookUpload.populateGradeData')

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

  equal(
    gradeData[submissionOld1Change.assignment_id][student1.previous_id].posted_grade,
    submissionOld1Change.grade
  )
  equal(gradeData[createAssignmentResponse1.id][student1.previous_id].excuse, true)
  equal(
    gradeData[createAssignmentResponse2.id][student1.previous_id].posted_grade,
    submissionNew2Change.grade
  )
  equal(gradeData[submissionOld2Excused.assignment_id][student2.previous_id].excuse, true)
  equal(
    gradeData[createAssignmentResponse1.id][student2.previous_id].posted_grade,
    submissionNew2Change.grade
  )
  equal(gradeData[createAssignmentResponse2.id][student2.previous_id].excuse, true)
  equal(gradeData[submissionOld1Excused.assignment_id][student3.previous_id].excuse, true)
  equal(
    gradeData[submissionOld2Change.assignment_id][student3.previous_id].posted_grade,
    submissionOld2Change.grade
  )
  equal(
    gradeData[createAssignmentResponse2.id][student3.previous_id].posted_grade,
    submissionNew2Change.grade
  )
})

QUnit.module('ProcessGradebookUpload.submitGradeData', {
  setup() {
    xhr = sinon.useFakeXMLHttpRequest()
    requests = []

    xhr.onCreate = function (request) {
      requests.push(request)
    }

    fakeENV.setup()
    ENV.bulk_update_path = '/bulk_update_path/url'
  },
  teardown() {
    xhr.restore()

    fakeENV.teardown()
  },
})

test('properly submits grade data', () => {
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

  equal(requests.length, 1)
  equal(requests[0].url, '/bulk_update_path/url')
  equal(requests[0].method, 'POST')

  const bulkUpdateRequest = JSON.parse(requests[0].requestBody)
  equal(bulkUpdateRequest.grade_data[1][1].posted_grade, 20)
  equal(bulkUpdateRequest.grade_data[1][2].excuse, true)
  equal(bulkUpdateRequest.grade_data[2][1].posted_grade, 25)
  equal(bulkUpdateRequest.grade_data[2][2].posted_grade, 15)
  equal(bulkUpdateRequest.grade_data[3][1].excuse, true)
  equal(bulkUpdateRequest.grade_data[3][2].excuse, true)
})

QUnit.module('ProcessGradebookUpload.upload', {
  setup() {
    sandbox.stub(window, 'alert')
    xhr = sinon.useFakeXMLHttpRequest()
    requests = []

    xhr.onCreate = function (request) {
      requests.push(request)
    }

    goToGradebookStub = sinon.stub(ProcessGradebookUpload, 'goToGradebook')

    clock = sinon.useFakeTimers()

    fakeENV.setup()
    ENV.create_assignment_path = '/create_assignment_path/url'
    ENV.bulk_update_path = '/bulk_update_path/url'
    ENV.bulk_update_override_scores_path = '/bulk_update_override_scores_path/url'
    ENV.custom_grade_statuses = [
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
  },
  teardown() {
    xhr.restore()

    ProcessGradebookUpload.goToGradebook.restore()

    clock.restore()

    fakeENV.teardown()
  },
})

test('sends no data to server if given null', () => {
  ProcessGradebookUpload.upload(null)
  equal(requests.length, 0)
})

test('sends no data to server if given an empty object', () => {
  ProcessGradebookUpload.upload({})
  equal(requests.length, 0)
})

test('sends no data to server if given a single existing assignment with no submissions', () => {
  const student = {previous_id: 1, submissions: []}
  const gradebook = {students: [student], assignments: [oldAssignment1]}
  ProcessGradebookUpload.upload(gradebook)

  equal(requests.length, 0)
})

test('sends no data to server if given a single existing assignment that requires no change', () => {
  const student = {previous_id: 1, submissions: [submissionOld1NoChange]}
  const gradebook = {students: [student], assignments: [oldAssignment1]}
  ProcessGradebookUpload.upload(gradebook)

  equal(requests.length, 0)
})

test('handles a grade change to a single existing assignment', () => {
  const student = {previous_id: 1, submissions: [submissionOld1Change]}
  const gradebook = {students: [student], assignments: [oldAssignment1]}
  ProcessGradebookUpload.upload(gradebook)
  clock.tick(1)

  equal(requests.length, 1)
  equal(requests[0].url, '/bulk_update_path/url')
  equal(requests[0].method, 'POST')

  const bulkUpdateRequest = JSON.parse(requests[0].requestBody)
  equal(
    bulkUpdateRequest.grade_data[oldAssignment1.id][student.previous_id].posted_grade,
    submissionOld1Change.grade
  )

  requests[0].respond(200, {}, JSON.stringify(progressCompleted))
  clock.tick(3)

  ok(goToGradebookStub.called)
})

test('handles a change to excused to a single existing assignment', () => {
  const student = {previous_id: 1, submissions: [submissionOld1Excused]}
  const gradebook = {students: [student], assignments: [oldAssignment1]}
  ProcessGradebookUpload.upload(gradebook)
  clock.tick(1)

  equal(requests.length, 1)
  equal(requests[0].url, '/bulk_update_path/url')
  equal(requests[0].method, 'POST')

  const bulkUpdateRequest = JSON.parse(requests[0].requestBody)
  equal(bulkUpdateRequest.grade_data[oldAssignment1.id][student.previous_id].excuse, true)

  requests[0].respond(200, {}, JSON.stringify(progressCompleted))
  clock.tick(3)

  ok(goToGradebookStub.called)
})

test('handles multiple students changing a single existing assignment', () => {
  const student1 = {previous_id: 1, submissions: [submissionOld1Change]}
  const student2 = {previous_id: 2, submissions: [submissionOld1Excused]}
  const gradebook = {students: [student1, student2], assignments: [oldAssignment1]}
  ProcessGradebookUpload.upload(gradebook)
  clock.tick(1)

  equal(requests.length, 1)
  equal(requests[0].url, '/bulk_update_path/url')
  equal(requests[0].method, 'POST')

  const bulkUpdateRequest = JSON.parse(requests[0].requestBody)
  equal(
    bulkUpdateRequest.grade_data[oldAssignment1.id][student1.previous_id].posted_grade,
    submissionOld1Change.grade
  )
  equal(bulkUpdateRequest.grade_data[oldAssignment1.id][student2.previous_id].excuse, true)

  requests[0].respond(200, {}, JSON.stringify(progressCompleted))
  clock.tick(3)

  ok(goToGradebookStub.called)
})

test('handles multiple students changing multiple existing assignments', () => {
  const student1 = {previous_id: 1, submissions: [submissionOld1Change, submissionOld2Excused]}
  const student2 = {previous_id: 2, submissions: [submissionOld1Excused, submissionOld2Change]}
  const gradebook = {students: [student1, student2], assignments: [oldAssignment1, oldAssignment2]}
  ProcessGradebookUpload.upload(gradebook)
  clock.tick(1)

  equal(requests.length, 1)
  equal(requests[0].url, '/bulk_update_path/url')
  equal(requests[0].method, 'POST')

  const bulkUpdateRequest = JSON.parse(requests[0].requestBody)
  equal(
    bulkUpdateRequest.grade_data[oldAssignment1.id][student1.previous_id].posted_grade,
    submissionOld1Change.grade
  )
  equal(bulkUpdateRequest.grade_data[oldAssignment1.id][student2.previous_id].excuse, true)
  equal(bulkUpdateRequest.grade_data[oldAssignment2.id][student1.previous_id].excuse, true)
  equal(
    bulkUpdateRequest.grade_data[oldAssignment2.id][student2.previous_id].posted_grade,
    submissionOld2Change.grade
  )

  requests[0].respond(200, {}, JSON.stringify(progressCompleted))
  clock.tick(3)

  ok(goToGradebookStub.called)
})

test('handles a creation of a new assignment with no submissions', () => {
  const student = {previous_id: 1, submissions: []}
  const gradebook = {students: [student], assignments: [newAssignment1]}
  ProcessGradebookUpload.upload(gradebook)
  clock.tick(1)

  equal(requests.length, 1)
  equal(requests[0].url, '/create_assignment_path/url')
  equal(requests[0].method, 'POST')

  const createAssignmentRequest = JSON.parse(requests[0].requestBody)
  equalAssignment(createAssignmentRequest.assignment, newAssignment1)

  requests[0].respond(200, {}, JSON.stringify(createAssignmentResponse1))
  clock.tick(3)

  ok(goToGradebookStub.called)
})

test('handles the creation of several new assignments with no submissions', () => {
  const student = {previous_id: 1, submissions: []}
  const gradebook = {students: [student], assignments: [newAssignment1, newAssignment2]}
  ProcessGradebookUpload.upload(gradebook)
  clock.tick(1)

  equal(requests.length, 2)

  equal(requests[0].url, '/create_assignment_path/url')
  equal(requests[0].method, 'POST')

  const createAssignmentRequest1 = JSON.parse(requests[0].requestBody)
  equalAssignment(createAssignmentRequest1.assignment, newAssignment1)

  requests[0].respond(200, {}, JSON.stringify(createAssignmentResponse1))
  clock.tick(3)

  equal(requests[1].url, '/create_assignment_path/url')
  equal(requests[1].method, 'POST')

  const createAssignmentRequest2 = JSON.parse(requests[1].requestBody)
  equalAssignment(createAssignmentRequest2.assignment, newAssignment2)

  requests[1].respond(200, {}, JSON.stringify(createAssignmentResponse2))
  clock.tick(3)

  ok(goToGradebookStub.called)
})

test('handles a creation of a new assignment with no grade change', () => {
  const student = {previous_id: 1, submissions: [submissionNew1NoChange]}
  const gradebook = {students: [student], assignments: [newAssignment1]}
  ProcessGradebookUpload.upload(gradebook)
  clock.tick(1)

  equal(requests.length, 1)
  equal(requests[0].url, '/create_assignment_path/url')
  equal(requests[0].method, 'POST')

  const createAssignmentRequest = JSON.parse(requests[0].requestBody)
  equalAssignment(createAssignmentRequest.assignment, newAssignment1)

  requests[0].respond(200, {}, JSON.stringify(createAssignmentResponse1))
  clock.tick(3)

  ok(goToGradebookStub.called)
})

test('handles creation of a new assignment with a grade change', () => {
  const student = {previous_id: 1, submissions: [submissionNew1Change]}
  const gradebook = {students: [student], assignments: [newAssignment1]}
  ProcessGradebookUpload.upload(gradebook)
  clock.tick(1)

  equal(requests.length, 1)
  equal(requests[0].url, '/create_assignment_path/url')
  equal(requests[0].method, 'POST')

  const createAssignmentRequest = JSON.parse(requests[0].requestBody)
  equalAssignment(createAssignmentRequest.assignment, newAssignment1)

  requests[0].respond(200, {}, JSON.stringify(createAssignmentResponse1))
  clock.tick(3)

  equal(requests.length, 2)
  equal(requests[1].url, '/bulk_update_path/url')
  equal(requests[1].method, 'POST')

  const bulkUpdateRequest = JSON.parse(requests[1].requestBody)
  equal(
    bulkUpdateRequest.grade_data[createAssignmentResponse1.id][student.previous_id].posted_grade,
    submissionNew1Change.grade
  )

  requests[1].respond(200, {}, JSON.stringify(progressCompleted))
  clock.tick(3)

  ok(goToGradebookStub.called)
})

test('handles creation of a new assignment with a change to excused', () => {
  const student = {previous_id: 1, submissions: [submissionNew1Excused]}
  const gradebook = {students: [student], assignments: [newAssignment1]}
  ProcessGradebookUpload.upload(gradebook)
  clock.tick(1)

  equal(requests.length, 1)
  equal(requests[0].url, '/create_assignment_path/url')
  equal(requests[0].method, 'POST')

  const createAssignmentRequest = JSON.parse(requests[0].requestBody)
  equalAssignment(createAssignmentRequest.assignment, newAssignment1)

  requests[0].respond(200, {}, JSON.stringify(createAssignmentResponse1))
  clock.tick(3)

  equal(requests.length, 2)
  equal(requests[1].url, '/bulk_update_path/url')
  equal(requests[1].method, 'POST')

  const bulkUpdateRequest = JSON.parse(requests[1].requestBody)
  equal(
    bulkUpdateRequest.grade_data[createAssignmentResponse1.id][student.previous_id].excuse,
    true
  )

  requests[1].respond(200, {}, JSON.stringify(progressCompleted))
  clock.tick(3)

  ok(goToGradebookStub.called)
})

test('handles multiple students changing a single new assignment', () => {
  const student1 = {previous_id: 1, submissions: [submissionNew1Change]}
  const student2 = {previous_id: 2, submissions: [submissionNew1Excused]}
  const gradebook = {students: [student1, student2], assignments: [newAssignment1]}
  ProcessGradebookUpload.upload(gradebook)
  clock.tick(1)

  equal(requests.length, 1)
  equal(requests[0].url, '/create_assignment_path/url')
  equal(requests[0].method, 'POST')

  const createAssignmentRequest = JSON.parse(requests[0].requestBody)
  equalAssignment(createAssignmentRequest.assignment, newAssignment1)

  requests[0].respond(200, {}, JSON.stringify(createAssignmentResponse1))
  clock.tick(3)

  equal(requests.length, 2)
  equal(requests[1].url, '/bulk_update_path/url')
  equal(requests[1].method, 'POST')

  const bulkUpdateRequest = JSON.parse(requests[1].requestBody)
  equal(
    bulkUpdateRequest.grade_data[createAssignmentResponse1.id][student1.previous_id].posted_grade,
    submissionNew1Change.grade
  )
  equal(
    bulkUpdateRequest.grade_data[createAssignmentResponse1.id][student2.previous_id].excuse,
    true
  )

  requests[1].respond(200, {}, JSON.stringify(progressCompleted))
  clock.tick(3)

  ok(goToGradebookStub.called)
})

test('handles multiple students changing multiple new assignments', () => {
  const student1 = {previous_id: 1, submissions: [submissionNew1Change, submissionNew2Excused]}
  const student2 = {previous_id: 2, submissions: [submissionNew1Excused, submissionNew2Change]}
  const gradebook = {students: [student1, student2], assignments: [newAssignment1, newAssignment2]}
  ProcessGradebookUpload.upload(gradebook)
  clock.tick(1)

  equal(requests.length, 2)

  equal(requests[0].url, '/create_assignment_path/url')
  equal(requests[0].method, 'POST')

  const createAssignmentRequest1 = JSON.parse(requests[0].requestBody)
  equalAssignment(createAssignmentRequest1.assignment, newAssignment1)

  requests[0].respond(200, {}, JSON.stringify(createAssignmentResponse1))
  clock.tick(3)

  equal(requests[1].url, '/create_assignment_path/url')
  equal(requests[1].method, 'POST')

  const createAssignmentRequest2 = JSON.parse(requests[1].requestBody)
  equalAssignment(createAssignmentRequest2.assignment, newAssignment2)

  requests[1].respond(200, {}, JSON.stringify(createAssignmentResponse2))
  clock.tick(3)

  equal(requests.length, 3)
  equal(requests[2].url, '/bulk_update_path/url')
  equal(requests[2].method, 'POST')

  const bulkUpdateRequest = JSON.parse(requests[2].requestBody)
  equal(
    bulkUpdateRequest.grade_data[createAssignmentResponse1.id][student1.previous_id].posted_grade,
    submissionNew1Change.grade
  )
  equal(
    bulkUpdateRequest.grade_data[createAssignmentResponse1.id][student2.previous_id].excuse,
    true
  )
  equal(
    bulkUpdateRequest.grade_data[createAssignmentResponse2.id][student1.previous_id].excuse,
    true
  )
  equal(
    bulkUpdateRequest.grade_data[createAssignmentResponse2.id][student2.previous_id].posted_grade,
    submissionNew2Change.grade
  )

  requests[2].respond(200, {}, JSON.stringify(progressCompleted))
  clock.tick(3)

  ok(goToGradebookStub.called)
})

test('handles multiple students changing multiple new and existing assignments', () => {
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
  ProcessGradebookUpload.upload(gradebook)
  clock.tick(1)

  equal(requests.length, 2)

  equal(requests[0].url, '/create_assignment_path/url')
  equal(requests[0].method, 'POST')

  const createAssignmentRequest1 = JSON.parse(requests[0].requestBody)
  equalAssignment(createAssignmentRequest1.assignment, newAssignment1)

  requests[0].respond(200, {}, JSON.stringify(createAssignmentResponse1))
  clock.tick(3)

  equal(requests[1].url, '/create_assignment_path/url')
  equal(requests[1].method, 'POST')

  const createAssignmentRequest2 = JSON.parse(requests[1].requestBody)
  equalAssignment(createAssignmentRequest2.assignment, newAssignment2)

  requests[1].respond(200, {}, JSON.stringify(createAssignmentResponse2))
  clock.tick(3)

  equal(requests.length, 3)
  equal(requests[2].url, '/bulk_update_path/url')
  equal(requests[2].method, 'POST')

  const bulkUpdateRequest = JSON.parse(requests[2].requestBody)
  equal(
    bulkUpdateRequest.grade_data[oldAssignment1.id][student1.previous_id].posted_grade,
    submissionOld1Change.grade
  )
  equal(bulkUpdateRequest.grade_data[oldAssignment1.id][student3.previous_id].excuse, true)
  equal(bulkUpdateRequest.grade_data[oldAssignment2.id][student2.previous_id].excuse, true)
  equal(
    bulkUpdateRequest.grade_data[oldAssignment2.id][student3.previous_id].posted_grade,
    submissionOld2Change.grade
  )
  equal(
    bulkUpdateRequest.grade_data[createAssignmentResponse1.id][student1.previous_id].excuse,
    true
  )
  equal(
    bulkUpdateRequest.grade_data[createAssignmentResponse1.id][student2.previous_id].posted_grade,
    submissionNew1Change.grade
  )
  equal(
    bulkUpdateRequest.grade_data[createAssignmentResponse2.id][student1.previous_id].posted_grade,
    submissionNew2Change.grade
  )
  equal(
    bulkUpdateRequest.grade_data[createAssignmentResponse2.id][student2.previous_id].excuse,
    true
  )
  equal(
    bulkUpdateRequest.grade_data[createAssignmentResponse2.id][student3.previous_id].posted_grade,
    submissionNew2Change.grade
  )

  requests[2].respond(200, {}, JSON.stringify(progressCompleted))
  clock.tick(3)

  ok(goToGradebookStub.called)
})

test('calls uploadCustomColumnData if custom_columns is non-empty', () => {
  sinon.stub(ProcessGradebookUpload, 'uploadCustomColumnData')

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

  equal(ProcessGradebookUpload.uploadCustomColumnData.callCount, 1)

  ProcessGradebookUpload.uploadCustomColumnData.restore()
})

test('does not call uploadCustomColumnData if custom_columns is empty', () => {
  sinon.stub(ProcessGradebookUpload, 'uploadCustomColumnData')

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

  equal(ProcessGradebookUpload.uploadCustomColumnData.callCount, 0)

  ProcessGradebookUpload.uploadCustomColumnData.restore()
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

  strictEqual(requests.length, 1)
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

  strictEqual(requests.length, 1)
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

  strictEqual(requests.length, 3)
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

  strictEqual(requests.length, 2)
  requests.forEach(request => {
    const body = request.requestBody
    const parsedBody = JSON.parse(body)
    if (parsedBody.grading_period_id === '1') {
      strictEqual(parsedBody.override_scores[0].override_score, '85')
      strictEqual(parsedBody.override_scores[0].override_status_id, 1)
    } else {
      strictEqual(parsedBody.override_scores[0].override_score, '80')
      strictEqual(parsedBody.override_scores[0].override_status_id, 2)
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
  delete ENV.bulk_update_override_scores_path
  ProcessGradebookUpload.upload(gradebook)

  strictEqual(requests.length, 0)
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

  strictEqual(window.alert.callCount, 1)
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

  strictEqual(window.alert.callCount, 0)
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

  const createAssignmentRequests = requests.filter(
    request => request.url === '/create_assignment_path/url'
  )
  createAssignmentRequests.forEach((request, idx) => {
    request.respond(200, {}, JSON.stringify({id: idx + 1000}))
  })
  clock.tick(3)

  const overrideScoreRequests = requests.filter(
    request => request.url === '/bulk_update_override_scores_path/url'
  )
  overrideScoreRequests.forEach(request => {
    request.respond(200, {}, JSON.stringify(progressQueued))
  })
  clock.tick(3)

  strictEqual(
    ProcessGradebookUpload.goToGradebook.callCount,
    0,
    'goToGradebook should not be called before submission bulk updates have started'
  )

  const uploadSubmissionsRequests = requests.filter(
    request => request.url === '/bulk_update_path/url'
  )
  uploadSubmissionsRequests.forEach(request => {
    request.respond(200, {}, JSON.stringify(progressQueued))
  })
  clock.tick(3)

  strictEqual(ProcessGradebookUpload.goToGradebook.callCount, 1)
})

QUnit.module('ProcessGradebookUpload.parseCustomColumnData')

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
  equal(data.length, 2)
  equal(data[0].user_id, 10)
  equal(data[0].column_id, 1)
  equal(data[0].content, 'first content')
  equal(data[1].user_id, 10)
  equal(data[1].column_id, 3)
  equal(data[1].content, 'second content')
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
  equal(data.length, 2)
  equal(data[0].user_id, 1)
  equal(data[0].column_id, 2)
  equal(data[0].content, 'second content')
  equal(data[1].user_id, 10)
  equal(data[1].column_id, 1)
  equal(data[1].content, 'first content')
})

QUnit.module('ProcessGradebookUpload.submitCustomColumnData', {
  setup() {
    sandbox.stub(window, 'alert')
    xhr = sinon.useFakeXMLHttpRequest()
    requests = []

    xhr.onCreate = function (request) {
      requests.push(request)
    }

    goToGradebookStub = sinon.stub(ProcessGradebookUpload, 'goToGradebook')

    clock = sinon.useFakeTimers()

    fakeENV.setup()
    ENV.bulk_update_custom_columns_path = '/bulk_update_custom_columns_path/url'
  },
  teardown() {
    xhr.restore()

    ProcessGradebookUpload.goToGradebook.restore()

    clock.restore()

    fakeENV.teardown()
  },
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

  equal(requests.length, 1)
  equal(requests[0].url, '/bulk_update_custom_columns_path/url')
  equal(requests[0].method, 'PUT')

  const bulkUpdateRequest = JSON.parse(requests[0].requestBody)
  equal(bulkUpdateRequest.column_data[0].column_id, 1)
  equal(bulkUpdateRequest.column_data[0].user_id, 2)
  equal(bulkUpdateRequest.column_data[0].content, 'test content')
  equal(bulkUpdateRequest.column_data[1].column_id, 3)
  equal(bulkUpdateRequest.column_data[1].user_id, 4)
  equal(bulkUpdateRequest.column_data[1].content, 'test content 2')
})

QUnit.module('ProcessGradebookUpload.createOverrideUpdateRequests', hooks => {
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

  let gradebook

  hooks.beforeEach(() => {
    xhr = sinon.useFakeXMLHttpRequest()
    requests = []

    xhr.onCreate = function (request) {
      requests.push(request)
    }

    fakeENV.setup({bulk_update_override_scores_path: '/bulk_update_override_scores_path'})

    gradebook = {
      students: [],
    }
  })

  hooks.afterEach(() => {
    xhr.restore()
    fakeENV.teardown()
  })

  test('creates an update request for each grading period/course with changed scores', () => {
    gradebook.students.push(studentWithMultipleUpdates)

    ProcessGradebookUpload.createOverrideUpdateRequests(gradebook)
    strictEqual(requests.length, 3, 'creates an update for each grading period/course')

    const urls = requests.map(request => request.url)
    strictEqual(
      urls[0],
      '/bulk_update_override_scores_path',
      'uses the URL specified in the environment'
    )
  })

  test('includes the grading_period_id in the parameters for updates for that grading period', () => {
    gradebook.students.push(studentWithGradingPeriodUpdate)
    ProcessGradebookUpload.createOverrideUpdateRequests(gradebook)

    const body = JSON.parse(requests[0].requestBody)
    strictEqual(body.grading_period_id, '1')
  })

  test('does not include grading_period_id if updating course scores', () => {
    gradebook.students.push(studentWithCourseGradeUpdate)
    ProcessGradebookUpload.createOverrideUpdateRequests(gradebook)

    const body = JSON.parse(requests[0].requestBody)
    equal(body.grading_period_id, null)
  })

  test('only includes override score updates containing changes to the scores', () => {
    gradebook.students.push(studentWithNoActualChanges)
    ProcessGradebookUpload.createOverrideUpdateRequests(gradebook)

    strictEqual(requests.length, 0)
  })

  test('includes the new score and student ID in the body of each request', () => {
    gradebook.students.push(studentWithGradingPeriodUpdate)
    ProcessGradebookUpload.createOverrideUpdateRequests(gradebook)

    const body = JSON.parse(requests[0].requestBody)
    deepEqual(body.override_scores, [{override_score: '90', student_id: '2'}])
  })
})
