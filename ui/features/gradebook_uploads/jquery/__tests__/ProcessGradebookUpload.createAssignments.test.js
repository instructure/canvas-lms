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

import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import ProcessGradebookUpload from '../process_gradebook_upload'
import fakeENV from '@canvas/test-utils/fakeENV'

// Helper to wait for async operations
const waitForAsync = () => new Promise(resolve => setTimeout(resolve, 0))

// Define constants
const oldAssignment1 = {id: 1, title: 'Old Assignment 1', points_possible: 25, published: true}
const oldAssignment2 = {id: 2, title: 'Old Assignment 2', points_possible: 25, published: true}
const newAssignment1 = {id: 0, title: 'New Assignment 1', points_possible: 25, published: true}
const newAssignment2 = {id: -1, title: 'New Assignment 2', points_possible: 25, published: true}

function equalAssignment(assignment1, assignment2) {
  expect(assignment1.name).toBe(assignment2.title)
  expect(assignment1.points_possible).toBe(assignment2.points_possible)
  expect(assignment1.published).toBe(assignment2.published)
}

describe('ProcessGradebookUpload.createIndividualAssignment', () => {
  const server = setupServer()
  let capturedRequest = null

  beforeAll(() => {
    server.listen()
  })

  beforeEach(() => {
    capturedRequest = null

    fakeENV.setup({
      create_assignment_path: '/create_assignment_path/url',
    })

    server.use(
      http.post('/create_assignment_path/url', async ({request}) => {
        capturedRequest = await request.json()
        return HttpResponse.json({id: 1})
      }),
    )
  })

  afterEach(() => {
    server.resetHandlers()
    fakeENV.teardown()
  })

  afterAll(() => {
    server.close()
  })

  test('properly creates a new assignment', async () => {
    ProcessGradebookUpload.createIndividualAssignment(oldAssignment1)
    await waitForAsync()

    expect(capturedRequest).not.toBeNull()
    equalAssignment(capturedRequest.assignment, oldAssignment1)
  })
})

describe('ProcessGradebookUpload.createAssignments', () => {
  const server = setupServer()
  const capturedRequests = []

  beforeAll(() => {
    server.listen()
  })

  beforeEach(() => {
    capturedRequests.length = 0

    fakeENV.setup({
      create_assignment_path: '/create_assignment_path/url',
    })

    server.use(
      http.post('/create_assignment_path/url', async ({request}) => {
        const body = await request.json()
        capturedRequests.push(body)
        return HttpResponse.json({id: Date.now()})
      }),
    )
  })

  afterEach(() => {
    server.resetHandlers()
    fakeENV.teardown()
  })

  afterAll(() => {
    server.close()
  })

  test('sends no data to server and returns an empty array if given no assignments', async () => {
    const gradebook = {assignments: []}
    const responses = ProcessGradebookUpload.createAssignments(gradebook)
    await waitForAsync()

    expect(capturedRequests).toHaveLength(0)
    expect(responses).toHaveLength(0)
  })

  test('properly filters and creates multiple assignments', async () => {
    const gradebook = {
      assignments: [oldAssignment1, oldAssignment2, newAssignment1, newAssignment2],
    }
    ProcessGradebookUpload.createAssignments(gradebook)
    await waitForAsync()

    expect(capturedRequests).toHaveLength(2)
    equalAssignment(capturedRequests[0].assignment, newAssignment1)
    equalAssignment(capturedRequests[1].assignment, newAssignment2)
  })

  test('sends calculate_grades: false as an argument when creating assignments', async () => {
    const gradebook = {
      assignments: [newAssignment1],
    }
    ProcessGradebookUpload.createAssignments(gradebook)
    await waitForAsync()

    expect(capturedRequests[0].calculate_grades).toBe(false)
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
