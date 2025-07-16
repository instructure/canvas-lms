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

const progressQueued = {id: 1, workflow_state: 'queued'}
const progressCompleted = {id: 1, workflow_state: 'completed'}

describe('ProcessGradebookUpload.submitGradeData', () => {
  const server = setupServer()
  let capturedRequest = null

  beforeAll(() => {
    server.listen()
  })

  beforeEach(() => {
    capturedRequest = null

    fakeENV.setup({
      bulk_update_path: '/bulk_update_path/url',
    })

    server.use(
      http.post('/bulk_update_path/url', async ({request}) => {
        capturedRequest = await request.json()
        return HttpResponse.json(progressCompleted)
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

  test('properly submits grade data', async () => {
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
    await waitForAsync()

    expect(capturedRequest).not.toBeNull()
    expect(capturedRequest.grade_data[1][1].posted_grade).toBe('20')
    expect(capturedRequest.grade_data[1][2].excuse).toBe(true)
    expect(capturedRequest.grade_data[2][1].posted_grade).toBe('25')
    expect(capturedRequest.grade_data[2][2].posted_grade).toBe('15')
    expect(capturedRequest.grade_data[3][1].excuse).toBe(true)
    expect(capturedRequest.grade_data[3][2].excuse).toBe(true)
  })
})

describe('ProcessGradebookUpload.submitCustomColumnData', () => {
  const server = setupServer()
  let capturedRequest = null

  beforeAll(() => {
    server.listen()
  })

  beforeEach(() => {
    capturedRequest = null

    fakeENV.setup({
      bulk_update_custom_columns_path: '/bulk_update_custom_columns_path/url',
    })

    server.use(
      http.put('/bulk_update_custom_columns_path/url', async ({request}) => {
        capturedRequest = await request.json()
        return HttpResponse.json(progressQueued)
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

  test('correctly submits custom column data', async () => {
    const customColumnsData = [
      {column_id: 10, user_id: 5, content: 'B'},
      {column_id: 10, user_id: 6, content: 'C'},
    ]
    const customColumn = {id: 10, title: 'Notes'}
    const gradebook = {
      students: [
        {id: 5, custom_column_data: [{column_id: 10, new_content: 'B'}]},
        {id: 6, custom_column_data: [{column_id: 10, new_content: 'C'}]},
      ],
      custom_columns: [customColumn],
    }
    ProcessGradebookUpload.submitCustomColumnData(customColumnsData, gradebook)
    await waitForAsync()

    expect(capturedRequest).not.toBeNull()
    expect(capturedRequest).toEqual({
      column_data: [
        {column_id: 10, user_id: 5, content: 'B'},
        {column_id: 10, user_id: 6, content: 'C'},
      ],
    })
  })
})

describe('ProcessGradebookUpload.createOverrideUpdateRequests', () => {
  const server = setupServer()
  const capturedRequests = []

  beforeAll(() => {
    server.listen()
  })

  beforeEach(() => {
    capturedRequests.length = 0

    fakeENV.setup({
      bulk_update_override_scores_path: '/bulk_update_override_scores_path/url',
      custom_grade_statuses: [
        {id: 'late_id', name: 'LATE'},
        {id: 'missing_id', name: 'MISSING'},
      ],
    })

    server.use(
      http.put('/bulk_update_override_scores_path/url', async ({request}) => {
        const body = await request.json()
        capturedRequests.push(body)
        return HttpResponse.json(progressQueued)
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

  test('creates requests for override score changes with no grading period', async () => {
    const gradebook = {
      students: [
        {
          id: '123',
          override_scores: [{current_score: '89', new_score: '78'}],
        },
        {
          id: '456',
          override_scores: [{current_score: '90', new_score: '92'}],
        },
      ],
    }
    ProcessGradebookUpload.createOverrideUpdateRequests(gradebook)
    await waitForAsync()

    expect(capturedRequests).toHaveLength(1)
    expect(capturedRequests[0].override_scores).toEqual([
      {student_id: '123', override_score: '78'},
      {student_id: '456', override_score: '92'},
    ])
  })

  test('creates requests for override score changes with grading period', async () => {
    const gradebook = {
      students: [
        {
          id: '123',
          override_scores: [{current_score: '89', new_score: '78', grading_period_id: '22'}],
        },
        {
          id: '456',
          override_scores: [{current_score: '90', new_score: '92', grading_period_id: '22'}],
        },
      ],
    }
    ProcessGradebookUpload.createOverrideUpdateRequests(gradebook)
    await waitForAsync()

    expect(capturedRequests).toHaveLength(1)
    expect(capturedRequests[0].override_scores).toEqual([
      {student_id: '123', override_score: '78'},
      {student_id: '456', override_score: '92'},
    ])
  })

  test('creates separate requests when multiple grading periods', async () => {
    const gradebook = {
      students: [
        {
          id: '123',
          override_scores: [
            {current_score: '89', new_score: '78', grading_period_id: '22'},
            {current_score: '88', new_score: '79', grading_period_id: '23'},
          ],
        },
        {
          id: '456',
          override_scores: [{current_score: '90', new_score: '92', grading_period_id: '22'}],
        },
      ],
    }
    ProcessGradebookUpload.createOverrideUpdateRequests(gradebook)
    await waitForAsync()

    expect(capturedRequests).toHaveLength(2)
  })

  test('creates requests for status changes', async () => {
    const gradebook = {
      students: [
        {
          id: '123',
          override_statuses: [{current_grade_status: null, new_grade_status: 'LATE'}],
        },
        {
          id: '456',
          override_statuses: [{current_grade_status: 'LATE', new_grade_status: 'MISSING'}],
        },
      ],
    }
    ProcessGradebookUpload.createOverrideUpdateRequests(gradebook)
    await waitForAsync()

    expect(capturedRequests).toHaveLength(1)
    expect(capturedRequests[0].override_scores).toEqual([
      {student_id: '123', override_status_id: 'late_id'},
      {student_id: '456', override_status_id: 'missing_id'},
    ])
  })

  test('does not create requests for null to null status changes', async () => {
    const gradebook = {
      students: [
        {
          id: '123',
          override_scores: [{current_grade_status: null, new_grade_status: null}],
        },
      ],
    }
    ProcessGradebookUpload.createOverrideUpdateRequests(gradebook)
    await waitForAsync()

    expect(capturedRequests).toHaveLength(0)
  })

  test('parses scores as floats', async () => {
    const gradebook = {
      students: [
        {
          id: '123',
          override_scores: [{current_score: '89.12', new_score: '78.34'}],
        },
      ],
    }
    ProcessGradebookUpload.createOverrideUpdateRequests(gradebook)
    await waitForAsync()

    expect(capturedRequests).toHaveLength(1)
    expect(capturedRequests[0].override_scores[0].override_score).toBe('78.34')
  })

  test('includes students with NaN scores if they have different values', async () => {
    const gradebook = {
      students: [
        {
          id: '123',
          override_scores: [{current_score: '89', new_score: 'not a number'}],
        },
        {
          id: '456',
          override_scores: [{current_score: '90', new_score: '92'}],
        },
      ],
    }
    ProcessGradebookUpload.createOverrideUpdateRequests(gradebook)
    await waitForAsync()

    expect(capturedRequests).toHaveLength(1)
    expect(capturedRequests[0].override_scores).toHaveLength(2)
    expect(capturedRequests[0].override_scores[0].student_id).toBe('123')
    expect(capturedRequests[0].override_scores[0].override_score).toBe('not a number')
    expect(capturedRequests[0].override_scores[1].student_id).toBe('456')
    expect(capturedRequests[0].override_scores[1].override_score).toBe('92')
  })

  test('skips students with unchanged scores', async () => {
    const gradebook = {
      students: [
        {
          id: '123',
          override_scores: [{current_score: '89', new_score: '89'}],
        },
        {
          id: '456',
          override_scores: [{current_score: '90', new_score: '92'}],
        },
      ],
    }
    ProcessGradebookUpload.createOverrideUpdateRequests(gradebook)
    await waitForAsync()

    expect(capturedRequests).toHaveLength(1)
    expect(capturedRequests[0].override_scores).toHaveLength(1)
    expect(capturedRequests[0].override_scores[0].student_id).toBe('456')
  })

  test('handles both score and status changes', async () => {
    const gradebook = {
      students: [
        {
          id: '123',
          override_scores: [
            {
              current_score: '89',
              new_score: '78',
              current_grade_status: null,
              new_grade_status: 'LATE',
            },
          ],
        },
      ],
    }
    ProcessGradebookUpload.createOverrideUpdateRequests(gradebook)
    await waitForAsync()

    expect(capturedRequests).toHaveLength(1)
    expect(capturedRequests[0].override_scores).toEqual([
      {student_id: '123', override_score: '78', override_status_id: 'late_id'},
    ])
  })
})
