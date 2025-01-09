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

import SubmissionCommentApi from '../SubmissionCommentApi'
import {underscoreProperties} from '@canvas/convert-case'
import sinon from 'sinon'

describe('SubmissionCommentApi.updateSubmissionComment', () => {
  let server
  const commentId = '12'
  const url = `/submission_comments/${commentId}`
  const updatedComment = 'an updated comment!'
  const editedAt = '2015-10-12T19:25:41Z'
  const submissionComment = {
    id: commentId,
    created_at: '2015-10-09T19:25:41Z',
    comment: updatedComment,
    edited_at: editedAt,
  }
  const responseBody = JSON.stringify({submission_comment: underscoreProperties(submissionComment)})

  beforeEach(() => {
    server = sinon.fakeServer.create({respondImmediately: true})
  })

  afterEach(() => {
    server.restore()
  })

  it('on success, returns the submission comment with the updated comment', async () => {
    server.respondWith('PUT', url, [200, {'Content-Type': 'application/json'}, responseBody])
    const response = await SubmissionCommentApi.updateSubmissionComment(commentId, updatedComment)
    expect(response.data.comment).toBe(updatedComment)
  })

  it('on success, returns the submission comment with an updated editedAt', async () => {
    server.respondWith('PUT', url, [200, {'Content-Type': 'application/json'}, responseBody])
    const response = await SubmissionCommentApi.updateSubmissionComment(commentId, updatedComment)
    expect(response.data.editedAt.getTime()).toBe(new Date(editedAt).getTime())
  })

  it('on failure, returns a rejected promise with the error', async () => {
    server.respondWith('PUT', url, [500, {'Content-Type': 'application/json'}, JSON.stringify({})])
    try {
      await SubmissionCommentApi.updateSubmissionComment(commentId, updatedComment)
    } catch (error) {
      expect(error.response.status).toBe(500)
    }
  })
})

describe('SubmissionCommentApi.createSubmissionComment', () => {
  let assignmentId
  let commentData
  let courseId
  let server
  let studentId
  let url

  beforeEach(() => {
    assignmentId = '2301'
    commentData = {group_comment: 0, text_comment: 'comment!'}
    courseId = '1201'
    studentId = '1101'
    server = sinon.fakeServer.create({respondImmediately: true})
    url = `/api/v1/courses/${courseId}/assignments/${assignmentId}/submissions/${studentId}`
  })

  afterEach(() => {
    server.restore()
  })

  it('builds data from comment data', async () => {
    const response = [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify({submission_comments: []}),
    ]
    server.respondWith('PUT', url, response)
    await SubmissionCommentApi.createSubmissionComment(
      courseId,
      assignmentId,
      studentId,
      commentData,
    )
    const {requestBody} = server.requests[0]
    expect(JSON.parse(requestBody)).toEqual({comment: {group_comment: 0, text_comment: 'comment!'}})
  })
})
