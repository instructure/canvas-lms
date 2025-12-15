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

// Mock globalUtils module
vi.mock('@canvas/util/globalUtils', () => ({
  windowAlert: vi.fn(),
}))

import {windowAlert} from '@canvas/util/globalUtils'

// Define constants
const oldAssignment1 = {id: 1, title: 'Old Assignment 1', points_possible: 25, published: true}
const submissionOld1NoChange = {assignment_id: 1, grade: '20', original_grade: '20'}
const submissionOld1Change = {assignment_id: 1, grade: '20', original_grade: '25'}
const submissionOld1Excused = {assignment_id: 1, grade: 'EX', original_grade: '20'}

const newAssignment1 = {id: 0, title: 'New Assignment 1', points_possible: 25, published: true}
const submissionNew1Change = {assignment_id: 0, grade: '20', original_grade: '25'}
const submissionNew1Excused = {assignment_id: 0, grade: 'EX', original_grade: '20'}

const customColumn1 = {id: 1, title: 'Notes', read_only: false}
const progressCompleted = {id: 1, workflow_state: 'completed'}

describe('ProcessGradebookUpload.upload', () => {
  const server = setupServer()
  let originalGoToGradebook
  let goToGradebookStub

  beforeAll(() => {
    server.listen()
  })

  beforeEach(() => {
    originalGoToGradebook = ProcessGradebookUpload.goToGradebook
    goToGradebookStub = vi.fn()
    ProcessGradebookUpload.goToGradebook = goToGradebookStub

    fakeENV.setup({
      create_assignment_path: '/create_assignment_path/url',
      bulk_update_path: '/bulk_update_path/url',
      bulk_update_override_scores_path: null, // Disable by default
      custom_grade_statuses: [],
    })

    // Reset handlers
    server.resetHandlers()

    // Default handlers
    server.use(
      http.post('/create_assignment_path/url', async () => {
        return HttpResponse.json({id: 3})
      }),
      http.post('/bulk_update_path/url', async () => {
        return HttpResponse.json(progressCompleted)
      }),
    )

    // Clear all mock function calls
    vi.clearAllMocks()
  })

  afterEach(() => {
    windowAlert.mockClear()
    ProcessGradebookUpload.goToGradebook = originalGoToGradebook
    server.resetHandlers()
    fakeENV.teardown()

    // Ensure all timers are cleared
    vi.clearAllTimers()
  })

  afterAll(() => {
    server.close()
  })

  test('sends no data to server if given null', async () => {
    await ProcessGradebookUpload.upload(null)
    expect(goToGradebookStub).not.toHaveBeenCalled()
  })

  test('sends no data to server if given an empty object', async () => {
    await ProcessGradebookUpload.upload({})
    expect(goToGradebookStub).not.toHaveBeenCalled()
  })

  test('sends no data to server if given a single existing assignment with no submissions', async () => {
    const student = {previous_id: 1, submissions: []}
    const gradebook = {students: [student], assignments: [oldAssignment1]}
    await ProcessGradebookUpload.upload(gradebook)

    // goToGradebook is always called, but no alert should be shown when no data is uploaded
    expect(goToGradebookStub).toHaveBeenCalled()
    expect(windowAlert).not.toHaveBeenCalled()
  })

  test('sends no data to server if given a single existing assignment that requires no change', async () => {
    const student = {previous_id: 1, submissions: [submissionOld1NoChange]}
    const gradebook = {students: [student], assignments: [oldAssignment1]}
    await ProcessGradebookUpload.upload(gradebook)

    // goToGradebook is always called, but no alert should be shown when no data is uploaded
    expect(goToGradebookStub).toHaveBeenCalled()
    expect(windowAlert).not.toHaveBeenCalled()
  })

  test('handles a grade change to a single existing assignment', async () => {
    const student = {previous_id: 1, submissions: [submissionOld1Change]}
    const gradebook = {students: [student], assignments: [oldAssignment1]}

    await ProcessGradebookUpload.upload(gradebook)

    expect(goToGradebookStub).toHaveBeenCalled()
    expect(windowAlert).toHaveBeenCalled()
  })

  test('handles a change to excused to a single existing assignment', async () => {
    const student = {previous_id: 1, submissions: [submissionOld1Excused]}
    const gradebook = {students: [student], assignments: [oldAssignment1]}

    await ProcessGradebookUpload.upload(gradebook)

    expect(goToGradebookStub).toHaveBeenCalled()
    expect(windowAlert).toHaveBeenCalled()
  })

  test('handles a creation of a new assignment with no submissions', async () => {
    const student = {previous_id: 1, submissions: []}
    const gradebook = {students: [student], assignments: [newAssignment1]}

    await ProcessGradebookUpload.upload(gradebook)

    expect(goToGradebookStub).toHaveBeenCalled()
    // No alert because no bulk data was uploaded
    expect(windowAlert).not.toHaveBeenCalled()
  })

  test('handles creation of a new assignment with a grade change', async () => {
    const student = {previous_id: 1, submissions: [submissionNew1Change]}
    const gradebook = {students: [student], assignments: [newAssignment1]}

    await ProcessGradebookUpload.upload(gradebook)

    expect(goToGradebookStub).toHaveBeenCalled()
    expect(windowAlert).toHaveBeenCalled()
  })

  test('handles creation of a new assignment with a change to excused', async () => {
    const student = {previous_id: 1, submissions: [submissionNew1Excused]}
    const gradebook = {students: [student], assignments: [newAssignment1]}

    await ProcessGradebookUpload.upload(gradebook)

    expect(goToGradebookStub).toHaveBeenCalled()
    expect(windowAlert).toHaveBeenCalled()
  })

  test('calls uploadCustomColumnData if custom_columns is non-empty', async () => {
    const uploadCustomColumnDataStub = vi.fn()
    const originalUploadCustomColumnData = ProcessGradebookUpload.uploadCustomColumnData
    ProcessGradebookUpload.uploadCustomColumnData = uploadCustomColumnDataStub

    const student1 = {
      previous_id: 1,
      submissions: [submissionOld1Change],
    }
    const gradebook = {
      students: [student1],
      assignments: [oldAssignment1],
      custom_columns: [customColumn1],
    }
    await ProcessGradebookUpload.upload(gradebook)

    expect(uploadCustomColumnDataStub).toHaveBeenCalledTimes(1)

    ProcessGradebookUpload.uploadCustomColumnData = originalUploadCustomColumnData
  })

  test('does not call uploadCustomColumnData if custom_columns is empty', async () => {
    const uploadCustomColumnDataStub = vi.fn()
    const originalUploadCustomColumnData = ProcessGradebookUpload.uploadCustomColumnData
    ProcessGradebookUpload.uploadCustomColumnData = uploadCustomColumnDataStub

    const student1 = {
      previous_id: 1,
      submissions: [submissionOld1Change],
    }
    const gradebook = {
      students: [student1],
      assignments: [oldAssignment1],
      custom_columns: [],
    }
    await ProcessGradebookUpload.upload(gradebook)

    expect(uploadCustomColumnDataStub).not.toHaveBeenCalled()

    ProcessGradebookUpload.uploadCustomColumnData = originalUploadCustomColumnData
  })

  test('shows an alert if any bulk data is being uploaded', async () => {
    const gradebook = {
      assignments: [
        {
          title: 'a new assignment',
          id: -1,
          points_possible: 10,
        },
      ],
      students: [
        {
          id: '1',
          submissions: [{assignment_id: -1, grade: '10', original_grade: '9'}],
        },
      ],
    }

    await ProcessGradebookUpload.upload(gradebook)

    expect(windowAlert).toHaveBeenCalled()
  })

  test('does not show an alert if the only changes involve creating new assignments', async () => {
    const gradebook = {
      assignments: [
        {
          title: 'a new assignment',
          id: -1,
          points_possible: 10,
        },
      ],
      students: [
        {
          id: '1',
          submissions: [],
        },
      ],
    }

    await ProcessGradebookUpload.upload(gradebook)

    expect(windowAlert).not.toHaveBeenCalled()
  })

  test('ignores override score changes if no update URL is set', async () => {
    const gradebook = {
      assignments: [oldAssignment1],
      students: [
        {
          id: 1,
          submissions: [],
          override_scores: [{current_score: '70', new_score: '75'}],
        },
      ],
    }
    await ProcessGradebookUpload.upload(gradebook)

    // goToGradebook is always called, but no alert should be shown since override scores are ignored
    expect(goToGradebookStub).toHaveBeenCalled()
    expect(windowAlert).not.toHaveBeenCalled()
  })

  // Test to ensure no async operations are left dangling
  test('completes all async operations before test ends', async () => {
    const student = {previous_id: 1, submissions: [submissionOld1Change]}
    const gradebook = {students: [student], assignments: [oldAssignment1]}

    await ProcessGradebookUpload.upload(gradebook)

    // Wait a bit to ensure no dangling promises
    await new Promise(resolve => setTimeout(resolve, 0))

    expect(goToGradebookStub).toHaveBeenCalled()
  })
})
