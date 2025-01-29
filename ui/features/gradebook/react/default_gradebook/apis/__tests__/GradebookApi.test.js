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

import _ from 'lodash'
import GradebookApi from '../GradebookApi'
import sinon from 'sinon'

describe('GradebookApi', () => {
  let server
  const createTeacherNotesColumnUrl = '/api/v1/courses/1201/custom_gradebook_columns'
  const customColumn = {
    id: '2401',
    hidden: false,
    position: 1,
    teacher_notes: true,
    title: 'Notes',
  }

  beforeEach(() => {
    server = sinon.fakeServer.create({respondImmediately: true})
    server.respondWith('POST', createTeacherNotesColumnUrl, [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(customColumn),
    ])
  })

  afterEach(() => {
    server.restore()
  })

  const getRequest = () =>
    _.find(server.requests, request => request.url.includes(createTeacherNotesColumnUrl))

  it('sends a post request to the "create teacher notes column" url', async () => {
    await GradebookApi.createTeacherNotesColumn('1201')
    const request = getRequest()
    expect(request.method).toBe('POST')
    expect(request.url).toBe(createTeacherNotesColumnUrl)
  })

  it('includes data to create a teacher notes column', async () => {
    await GradebookApi.createTeacherNotesColumn('1201')
    const bodyData = JSON.parse(getRequest().requestBody)
    expect(bodyData.column.title).toBe('Notes')
    expect(bodyData.column.position).toBe(1)
    expect(bodyData.column.teacher_notes).toBe(true)
  })

  it('includes required request headers', async () => {
    await GradebookApi.createTeacherNotesColumn('1201')
    const {requestHeaders} = getRequest()
    expect(requestHeaders.Accept).toContain('application/json+canvas-string-ids')
    expect(requestHeaders['Content-Type']).toContain('application/json')
    expect(requestHeaders['X-Requested-With']).toBe('XMLHttpRequest')
  })

  it('sends the column data to the success handler', async () => {
    const {data} = await GradebookApi.createTeacherNotesColumn('1201')
    expect(data).toEqual(customColumn)
  })

  describe('GradebookApi.updateTeacherNotesColumn', () => {
    const updateTeacherNotesColumnUrl = '/api/v1/courses/1201/custom_gradebook_columns/2401'

    beforeEach(() => {
      server.respondWith('PUT', updateTeacherNotesColumnUrl, [
        200,
        {'Content-Type': 'application/json'},
        JSON.stringify(customColumn),
      ])
    })

    const getRequest = () =>
      _.find(server.requests, request => request.url.includes(updateTeacherNotesColumnUrl))

    it('sends a put request to the "update teacher notes column" url', async () => {
      await GradebookApi.updateTeacherNotesColumn('1201', '2401', {hidden: true})
      const request = getRequest()
      expect(request.method).toBe('PUT')
      expect(request.url).toBe(updateTeacherNotesColumnUrl)
    })

    it('includes params for updating a teacher notes column', async () => {
      await GradebookApi.updateTeacherNotesColumn('1201', '2401', {hidden: true})
      const bodyData = JSON.parse(getRequest().requestBody)
      expect(bodyData.column.hidden).toBe(true)
    })

    it('includes required request headers', async () => {
      await GradebookApi.updateTeacherNotesColumn('1201', '2401', {hidden: true})
      const {requestHeaders} = getRequest()
      expect(requestHeaders.Accept).toContain('application/json+canvas-string-ids')
      expect(requestHeaders['Content-Type']).toContain('application/json')
      expect(requestHeaders['X-Requested-With']).toBe('XMLHttpRequest')
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

    beforeEach(() => {
      server.respondWith('PUT', updateSubmissionUrl, [
        200,
        {'Content-Type': 'application/json'},
        JSON.stringify(submissionData),
      ])
    })

    const getRequest = () =>
      _.find(server.requests, request => request.url.includes(updateSubmissionUrl))

    it('sends a put request to the "update submission" url', async () => {
      await GradebookApi.updateSubmission(courseId, assignmentId, userId, {
        latePolicyStatus: 'none',
      })
      const request = getRequest()
      expect(request.method).toBe('PUT')
      expect(request.url).toBe(updateSubmissionUrl)
    })

    it('includes params for updating a submission', async () => {
      await GradebookApi.updateSubmission(courseId, assignmentId, userId, {
        latePolicyStatus: 'none',
      })
      const bodyData = JSON.parse(getRequest().requestBody)
      expect(bodyData.submission.late_policy_status).toBe('none')
    })

    it('includes params to request visibility for the submission', async () => {
      await GradebookApi.updateSubmission(courseId, assignmentId, userId, {
        latePolicyStatus: 'none',
      })
      const bodyData = JSON.parse(getRequest().requestBody)
      expect(bodyData.include.includes('visibility')).toBe(true)
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
      const bodyData = JSON.parse(getRequest().requestBody)
      expect(bodyData.prefer_points_over_scheme).toBe(true)
    })

    it('sends false for prefer_points_over_scheme param when not passed "points"', async () => {
      await GradebookApi.updateSubmission(
        courseId,
        assignmentId,
        userId,
        {latePolicyStatus: 'none'},
        'percent',
      )
      const bodyData = JSON.parse(getRequest().requestBody)
      expect(bodyData.prefer_points_over_scheme).toBe(false)
    })
  })
})
