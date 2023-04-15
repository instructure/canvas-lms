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
import GradebookApi from 'ui/features/gradebook/react/default_gradebook/apis/GradebookApi'

QUnit.module('GradebookApi.createTeacherNotesColumn', {
  setup() {
    this.customColumn = {
      id: '2401',
      hidden: false,
      position: 1,
      teacher_notes: true,
      title: 'Notes',
    }
    this.createTeacherNotesColumnUrl = '/api/v1/courses/1201/custom_gradebook_columns'
    this.server = sinon.fakeServer.create({respondImmediately: true})
    const responseBody = JSON.stringify(this.customColumn)
    this.server.respondWith('POST', this.createTeacherNotesColumnUrl, [
      200,
      {'Content-Type': 'application/json'},
      responseBody,
    ])
  },

  getRequest() {
    // filter requests to eliminate spec pollution from unrelated specs
    return _.find(this.server.requests, request =>
      request.url.includes(this.createTeacherNotesColumnUrl)
    )
  },

  teardown() {
    this.server.restore()
  },
})

test('sends a post request to the "create teacher notes column" url', function () {
  return GradebookApi.createTeacherNotesColumn('1201').then(() => {
    const request = this.getRequest()
    equal(request.method, 'POST')
    equal(request.url, this.createTeacherNotesColumnUrl)
  })
})

test('includes data to create a teacher notes column', function () {
  return GradebookApi.createTeacherNotesColumn('1201').then(() => {
    const bodyData = JSON.parse(this.getRequest().requestBody)
    equal(bodyData.column.title, 'Notes')
    strictEqual(bodyData.column.position, 1)
    equal(bodyData.column.teacher_notes, true)
  })
})

test('includes required request headers', function () {
  return GradebookApi.createTeacherNotesColumn('1201').then(() => {
    const {requestHeaders} = this.getRequest()
    ok(
      requestHeaders.Accept.includes('application/json+canvas-string-ids'),
      'includes header for Canvas string ids'
    )
    ok(
      requestHeaders['Content-Type'].includes('application/json'),
      'includes "application/json" content type'
    )
    equal(requestHeaders['X-Requested-With'], 'XMLHttpRequest')
  })
})

test('sends the column data to the success handler', function () {
  return GradebookApi.createTeacherNotesColumn('1201').then(({data}) => {
    deepEqual(data, this.customColumn)
  })
})

QUnit.module('GradebookApi.updateTeacherNotesColumn', {
  setup() {
    this.customColumn = {id: '2401', hidden: true, position: 1, teacher_notes: true, title: 'Notes'}
    this.updateTeacherNotesColumnUrl = '/api/v1/courses/1201/custom_gradebook_columns/2401'
    this.server = sinon.fakeServer.create({respondImmediately: true})
    const responseBody = JSON.stringify(this.customColumn)
    this.server.respondWith('PUT', this.updateTeacherNotesColumnUrl, [
      200,
      {'Content-Type': 'application/json'},
      responseBody,
    ])
  },

  getRequest() {
    // filter requests to eliminate spec pollution from unrelated specs
    return _.find(this.server.requests, request =>
      request.url.includes(this.updateTeacherNotesColumnUrl)
    )
  },

  teardown() {
    this.server.restore()
  },
})

test('sends a post request to the "create teacher notes column" url', function () {
  return GradebookApi.updateTeacherNotesColumn('1201', '2401', {hidden: true}).then(() => {
    const request = this.getRequest()
    equal(request.method, 'PUT')
    equal(request.url, this.updateTeacherNotesColumnUrl)
  })
})

test('includes params for updating a teacher notes column', function () {
  return GradebookApi.updateTeacherNotesColumn('1201', '2401', {hidden: true}).then(() => {
    const bodyData = JSON.parse(this.getRequest().requestBody)
    equal(bodyData.column.hidden, true)
  })
})

test('includes required request headers', function () {
  return GradebookApi.updateTeacherNotesColumn('1201', '2401', {hidden: true}).then(() => {
    const {requestHeaders} = this.getRequest()
    ok(
      requestHeaders.Accept.includes('application/json+canvas-string-ids'),
      'includes header for Canvas string ids'
    )
    ok(
      requestHeaders['Content-Type'].includes('application/json'),
      'includes "application/json" content type'
    )
    equal(requestHeaders['X-Requested-With'], 'XMLHttpRequest')
  })
})

test('sends the column data to the success handler', function () {
  return GradebookApi.updateTeacherNotesColumn('1201', '2401', {hidden: true}).then(({data}) => {
    deepEqual(data, this.customColumn)
  })
})

QUnit.module('GradebookApi.updateSubmission', hooks => {
  const courseId = '1201'
  const assignmentId = '303'
  const userId = '201'
  const updateSubmissionUrl = `/api/v1/courses/${courseId}/assignments/${assignmentId}/submissions/${userId}`
  const submissionData = {all_submissions: [{id: 301, late_policy_status: 'none'}]}
  let server

  hooks.beforeEach(() => {
    server = sinon.fakeServer.create({respondImmediately: true})
    const responseBody = JSON.stringify(submissionData)
    server.respondWith('PUT', updateSubmissionUrl, [
      200,
      {'Content-Type': 'application/json'},
      responseBody,
    ])
  })

  hooks.afterEach(() => {
    server.restore()
  })

  function getRequest() {
    // filter requests to eliminate spec pollution from unrelated specs
    return _.find(server.requests, request => request.url.includes(updateSubmissionUrl))
  }

  test('sends a put request to the "update submission" url', () =>
    GradebookApi.updateSubmission(courseId, assignmentId, userId, {
      latePolicyStatus: 'none',
    }).then(() => {
      const request = getRequest()
      strictEqual(request.method, 'PUT')
      strictEqual(request.url, updateSubmissionUrl)
    }))

  test('includes params for updating a submission', () =>
    GradebookApi.updateSubmission(courseId, assignmentId, userId, {
      latePolicyStatus: 'none',
    }).then(() => {
      const bodyData = JSON.parse(getRequest().requestBody)
      deepEqual(bodyData.submission.late_policy_status, 'none')
    }))

  test('includes params to request visibility for the submission', () =>
    GradebookApi.updateSubmission(courseId, assignmentId, userId, {
      latePolicyStatus: 'none',
    }).then(() => {
      const bodyData = JSON.parse(getRequest().requestBody)
      strictEqual(bodyData.include.includes('visibility'), true)
    }))

  test('sends the column data to the success handler', () =>
    GradebookApi.updateSubmission(courseId, assignmentId, userId, {
      latePolicyStatus: 'none',
    }).then(({data}) => {
      deepEqual(data, submissionData)
    }))

  test('sends true for prefer_points_over_scheme param when passed "points"', () =>
    GradebookApi.updateSubmission(
      courseId,
      assignmentId,
      userId,
      {
        latePolicyStatus: 'none',
      },
      'points'
    ).then(() => {
      const bodyData = JSON.parse(getRequest().requestBody)
      strictEqual(bodyData.prefer_points_over_scheme, true)
    }))

  test('sends false for prefer_points_over_scheme param when not passed "points"', () =>
    GradebookApi.updateSubmission(
      courseId,
      assignmentId,
      userId,
      {
        latePolicyStatus: 'none',
      },
      'percent'
    ).then(() => {
      const bodyData = JSON.parse(getRequest().requestBody)
      strictEqual(bodyData.prefer_points_over_scheme, false)
    }))
})
