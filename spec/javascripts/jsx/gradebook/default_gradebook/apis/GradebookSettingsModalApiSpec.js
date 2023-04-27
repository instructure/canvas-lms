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

import {underscoreProperties} from '@canvas/convert-case'
import FakeServer, {
  jsonBodyFromRequest,
  pathFromRequest,
} from '@canvas/network/NaiveRequestDispatch/__tests__/FakeServer'
import {
  DEFAULT_LATE_POLICY_DATA,
  fetchLatePolicy,
  createLatePolicy,
  updateCourseSettings,
  updateLatePolicy,
} from 'ui/features/gradebook/react/default_gradebook/apis/GradebookSettingsModalApi'

const latePolicyData = {
  id: '15',
  missingSubmissionDeductionEnabled: false,
  missingSubmissionDeduction: 76.0,
  lateSubmissionDeductionEnabled: true,
  lateSubmissionDeduction: 10.0,
  lateSubmissionInterval: 'day',
  lateSubmissionMinimumPercentEnabled: true,
  lateSubmissionMinimumPercent: 40.0,
}

function getRequestWithUrl(server, url) {
  // filter requests to eliminate spec pollution from unrelated specs
  return _.find(server.requests, request => request.url.includes(url))
}

QUnit.module('GradebookSettingsModalApi.fetchLatePolicy success', {
  setup() {
    this.url = '/api/v1/courses/19/late_policy'
    this.server = sinon.fakeServer.create({respondImmediately: true})
    const responseBody = JSON.stringify({late_policy: underscoreProperties(latePolicyData)})
    this.server.respondWith('GET', this.url, [
      200,
      {'Content-Type': 'application/json'},
      responseBody,
    ])
  },

  teardown() {
    this.server.restore()
  },
})

test('returns the late policy', () =>
  fetchLatePolicy('19').then(({data}) => {
    deepEqual(data, {latePolicy: latePolicyData})
  }))

QUnit.module('GradebookSettingsModalApi.fetchLatePolicy when late policy does not exist', {
  setup() {
    this.url = '/api/v1/courses/19/late_policy'
    this.server = sinon.fakeServer.create({respondImmediately: true})
    const responseBody = JSON.stringify({
      errors: [{message: 'The specified resource does not exist.'}],
      error_report_id: '2199',
    })
    this.server.respondWith('GET', this.url, [
      404,
      {'Content-Type': 'application/json'},
      responseBody,
    ])
  },

  teardown() {
    this.server.restore()
  },
})

test('returns default late policy data when the response is a 404', () =>
  fetchLatePolicy('19').then(({data}) => {
    deepEqual(data, {latePolicy: DEFAULT_LATE_POLICY_DATA})
  }))

QUnit.module('GradebookSettingsModalApi.fetchLatePolicy when the request fails', {
  setup() {
    this.url = '/api/v1/courses/19/late_policy'
    this.server = sinon.fakeServer.create({respondImmediately: true})
    this.server.respondWith('GET', this.url, [
      500,
      {'Content-Type': 'application/json'},
      JSON.stringify({}),
    ])
  },

  teardown() {
    this.server.restore()
  },
})

test('rejects the promise when the response is not a 200 or a 404', () =>
  fetchLatePolicy('19').catch(error => {
    strictEqual(error.response.status, 500)
  }))

QUnit.module('GradebookSettingsModalApi.createLatePolicy', {
  setup() {
    this.latePolicyCreationData = {...latePolicyData}
    delete this.latePolicyCreationData.id
    this.url = '/api/v1/courses/19/late_policy'
    this.server = sinon.fakeServer.create({respondImmediately: true})
    const responseBody = JSON.stringify({late_policy: underscoreProperties(latePolicyData)})
    this.server.respondWith('POST', this.url, [
      200,
      {'Content-Type': 'application/json'},
      responseBody,
    ])
  },

  teardown() {
    this.server.restore()
  },
})

test('includes data to create a late_policy', function () {
  return createLatePolicy('19', latePolicyData).then(() => {
    const bodyData = JSON.parse(getRequestWithUrl(this.server, this.url).requestBody)
    deepEqual(bodyData, {late_policy: underscoreProperties(latePolicyData)})
  })
})

test('returns the late policy', function () {
  return createLatePolicy('19', this.latePolicyCreationData).then(({data}) => {
    deepEqual(data, {latePolicy: latePolicyData})
  })
})

QUnit.module('GradebookSettingsModalApi.updateLatePolicy', {
  setup() {
    this.url = '/api/v1/courses/19/late_policy'
    this.changes = {lateSubmissionInterval: 'hour'}
    this.server = sinon.fakeServer.create({respondImmediately: true})
    this.server.respondWith('PATCH', this.url, [204, {}, ''])
  },

  teardown() {
    this.server.restore()
  },
})

test('includes data to update a late_policy', function () {
  return updateLatePolicy('19', this.changes).then(() => {
    const bodyData = JSON.parse(getRequestWithUrl(this.server, this.url).requestBody)
    deepEqual(bodyData, {late_policy: underscoreProperties(this.changes)})
  })
})

test('returns a 204 (successfully fulfilled request and no content)', function () {
  return updateLatePolicy('19', this.changes).then(({status}) => {
    equal(status, 204)
  })
})

QUnit.module('GradebookSettingsModalApi', suiteHooks => {
  let server

  suiteHooks.beforeEach(() => {
    server = new FakeServer()
  })

  suiteHooks.afterEach(() => {
    server.teardown()
  })

  QUnit.module('.updateCourseSettings()', hooks => {
    let responseData

    hooks.beforeEach(() => {
      responseData = {
        allow_final_grade_override: true,
      }

      server.for('/api/v1/courses/1201/settings').respond({status: 200, body: responseData})
    })

    test('sends a request to update course settings', async () => {
      await updateCourseSettings('1201', {allowFinalGradeOverride: true})
      const request = server.receivedRequests[0]
      equal(pathFromRequest(request), '/api/v1/courses/1201/settings')
    })

    test('sends a PUT request', async () => {
      await updateCourseSettings('1201', {allowFinalGradeOverride: true})
      const request = server.receivedRequests[0]
      equal(request.method, 'PUT')
    })

    test('normalizes the request body with snake case', async () => {
      await updateCourseSettings('1201', {allowFinalGradeOverride: true})
      const request = server.receivedRequests[0]
      deepEqual(jsonBodyFromRequest(request), {allow_final_grade_override: true})
    })

    test('normalizes the response body with camel case upon success', async () => {
      const response = await updateCourseSettings('1201', {allowFinalGradeOverride: true})
      deepEqual(response.data, {allowFinalGradeOverride: true})
    })

    test('does not catch errors', async () => {
      // Catching errors is the responsibility of the consumer.
      server.unsetResponses('/api/v1/courses/1201/settings')
      server
        .for('/api/v1/courses/1201/settings')
        .respond({status: 500, body: {error: 'Server Error'}})
      try {
        await updateCourseSettings('1201', {allowFinalGradeOverride: true})
      } catch (error) {
        ok(error.message.includes('500'))
      }
    })
  })
})
