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

import {http} from 'msw'
import {setupServer} from 'msw/node'
import GradebookApi from '../GradebookApi'

describe('GradebookApi', () => {
  const createTeacherNotesColumnUrl = '/api/v1/courses/1201/custom_gradebook_columns'
  const customColumn = {
    id: '2401',
    hidden: false,
    position: 1,
    teacher_notes: true,
    title: 'Notes',
  }

  let capturedRequest = null

  const server = setupServer(
    http.post(createTeacherNotesColumnUrl, async ({request}) => {
      capturedRequest = {
        method: request.method,
        url: request.url,
        headers: Object.fromEntries(request.headers.entries()),
        body: await request.json(),
      }
      return new Response(JSON.stringify(customColumn), {
        headers: {'Content-Type': 'application/json'},
      })
    }),
  )

  beforeAll(() => {
    server.listen({
      onUnhandledRequest: 'error',
    })
  })

  beforeEach(() => {
    capturedRequest = null
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  it('sends a post request to the "create teacher notes column" url', async () => {
    await GradebookApi.createTeacherNotesColumn('1201')
    expect(capturedRequest.method).toBe('POST')
    expect(capturedRequest.url).toContain(createTeacherNotesColumnUrl)
  })

  it('includes data to create a teacher notes column', async () => {
    await GradebookApi.createTeacherNotesColumn('1201')
    expect(capturedRequest.body.column.title).toBe('Notes')
    expect(capturedRequest.body.column.position).toBe(1)
    expect(capturedRequest.body.column.teacher_notes).toBe(true)
  })

  it('includes required request headers', async () => {
    await GradebookApi.createTeacherNotesColumn('1201')
    expect(capturedRequest.headers.accept).toContain('application/json+canvas-string-ids')
    expect(capturedRequest.headers['content-type']).toContain('application/json')
    expect(capturedRequest.headers['x-requested-with']).toBe('XMLHttpRequest')
  })

  it('sends the column data to the success handler', async () => {
    const {data} = await GradebookApi.createTeacherNotesColumn('1201')
    expect(data).toEqual(customColumn)
  })

  describe('GradebookApi.updateTeacherNotesColumn', () => {
    const updateTeacherNotesColumnUrl = '/api/v1/courses/1201/custom_gradebook_columns/2401'
    let updateCapturedRequest = null

    beforeEach(() => {
      updateCapturedRequest = null
      server.use(
        http.put(updateTeacherNotesColumnUrl, async ({request}) => {
          updateCapturedRequest = {
            method: request.method,
            url: request.url,
            headers: Object.fromEntries(request.headers.entries()),
            body: await request.json(),
          }
          return new Response(JSON.stringify(customColumn), {
            headers: {'Content-Type': 'application/json'},
          })
        }),
      )
    })

    it('sends a put request to the "update teacher notes column" url', async () => {
      await GradebookApi.updateTeacherNotesColumn('1201', '2401', {hidden: true})
      expect(updateCapturedRequest.method).toBe('PUT')
      expect(updateCapturedRequest.url).toContain(updateTeacherNotesColumnUrl)
    })

    it('includes params for updating a teacher notes column', async () => {
      await GradebookApi.updateTeacherNotesColumn('1201', '2401', {hidden: true})
      expect(updateCapturedRequest.body.column.hidden).toBe(true)
    })

    it('includes required request headers', async () => {
      await GradebookApi.updateTeacherNotesColumn('1201', '2401', {hidden: true})
      expect(updateCapturedRequest.headers.accept).toContain('application/json+canvas-string-ids')
      expect(updateCapturedRequest.headers['content-type']).toContain('application/json')
      expect(updateCapturedRequest.headers['x-requested-with']).toBe('XMLHttpRequest')
    })

    it('sends the column data to the success handler', async () => {
      const {data} = await GradebookApi.updateTeacherNotesColumn('1201', '2401', {hidden: true})
      expect(data).toEqual(customColumn)
    })
  })

  describe('GradebookApi.updateSubmission', () => {
    const courseId = '1201'
    const assignmentId = '303'
    const userId = '201'
    const updateSubmissionUrl = `/api/v1/courses/${courseId}/assignments/${assignmentId}/submissions/${userId}`
    const submissionData = {all_submissions: [{id: 301, late_policy_status: 'none'}]}
    let submissionCapturedRequest = null

    beforeEach(() => {
      submissionCapturedRequest = null
      server.use(
        http.put(updateSubmissionUrl, async ({request}) => {
          submissionCapturedRequest = {
            method: request.method,
            url: request.url,
            headers: Object.fromEntries(request.headers.entries()),
            body: await request.json(),
          }
          return new Response(JSON.stringify(submissionData), {
            headers: {'Content-Type': 'application/json'},
          })
        }),
      )
    })

    it('sends a put request to the "update submission" url', async () => {
      await GradebookApi.updateSubmission(courseId, assignmentId, userId, {
        latePolicyStatus: 'none',
      })
      expect(submissionCapturedRequest.method).toBe('PUT')
      expect(submissionCapturedRequest.url).toContain(updateSubmissionUrl)
    })

    it('includes params for updating a submission', async () => {
      await GradebookApi.updateSubmission(courseId, assignmentId, userId, {
        latePolicyStatus: 'none',
      })
      expect(submissionCapturedRequest.body.submission.late_policy_status).toBe('none')
    })

    it('includes params to request visibility for the submission', async () => {
      await GradebookApi.updateSubmission(courseId, assignmentId, userId, {
        latePolicyStatus: 'none',
      })
      expect(submissionCapturedRequest.body.include.includes('visibility')).toBe(true)
    })

    it('sends the column data to the success handler', async () => {
      const {data} = await GradebookApi.updateSubmission(courseId, assignmentId, userId, {
        latePolicyStatus: 'none',
      })
      expect(data).toEqual(submissionData)
    })

    it('sends true for prefer_points_over_scheme param when passed "points"', async () => {
      await GradebookApi.updateSubmission(
        courseId,
        assignmentId,
        userId,
        {latePolicyStatus: 'none'},
        'points',
      )
      expect(submissionCapturedRequest.body.prefer_points_over_scheme).toBe(true)
    })

    it('sends false for prefer_points_over_scheme param when not passed "points"', async () => {
      await GradebookApi.updateSubmission(
        courseId,
        assignmentId,
        userId,
        {latePolicyStatus: 'none'},
        'percent',
      )
      expect(submissionCapturedRequest.body.prefer_points_over_scheme).toBe(false)
    })
  })
})
