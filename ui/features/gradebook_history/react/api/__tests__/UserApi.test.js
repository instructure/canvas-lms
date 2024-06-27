/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import axios from '@canvas/axios'
import UserApi from '../UserApi'
import sinon from 'sinon'

const sandbox = sinon.createSandbox()
const deepEqual = (x, y) => expect(x).toEqual(y)
const strictEqual = (x, y) => expect(x).toEqual(y)

let courseId
let getStub

describe('UserApi', () => {
  beforeEach(() => {
    courseId = 525600
    getStub = sandbox.stub(axios, 'get').returns(
      Promise.resolve({
        response: {},
      })
    )
  })

  afterEach(() => {
    // restore the environment as it was before
    sandbox.restore()
  })

  test('getUsersByName for graders searches by teachers and TAs in a course', function () {
    const searchTerm = 'Norval'
    const url = `/api/v1/courses/${courseId}/users`
    const params = {
      params: {
        search_term: searchTerm,
        enrollment_type: ['teacher', 'ta'],
        enrollment_state: [],
      },
    }
    const promise = UserApi.getUsersByName(courseId, 'graders', searchTerm)

    return promise.then(() => {
      strictEqual(getStub.callCount, 1)
      strictEqual(getStub.firstCall.args[0], url)
      deepEqual(getStub.firstCall.args[1], params)
    })
  })

  test('getUsersByName for students searches by students', function () {
    const searchTerm = 'Norval'
    const url = `/api/v1/courses/${courseId}/users`
    const params = {
      params: {
        search_term: searchTerm,
        enrollment_type: ['student', 'student_view'],
        enrollment_state: [],
      },
    }
    const promise = UserApi.getUsersByName(courseId, 'students', searchTerm)

    return promise.then(() => {
      strictEqual(getStub.callCount, 1)
      strictEqual(getStub.firstCall.args[0], url)
      deepEqual(getStub.firstCall.args[1], params)
    })
  })

  test('getUsersByName restricts results by enrollment state if specified', function () {
    const searchTerm = 'Norval'
    const enrollmentState = ['completed']
    const url = `/api/v1/courses/${courseId}/users`
    const params = {
      params: {
        search_term: searchTerm,
        enrollment_type: ['student', 'student_view'],
        enrollment_state: enrollmentState,
      },
    }
    const promise = UserApi.getUsersByName(courseId, 'students', searchTerm, ['completed'])

    return promise.then(() => {
      strictEqual(getStub.callCount, 1)
      strictEqual(getStub.firstCall.args[0], url)
      deepEqual(getStub.firstCall.args[1], params)
    })
  })

  test('getUsersByName does not restrict results by enrollment state if argument omitted', function () {
    const searchTerm = 'Norval'
    const url = `/api/v1/courses/${courseId}/users`
    const params = {
      params: {
        search_term: searchTerm,
        enrollment_type: ['student', 'student_view'],
        enrollment_state: [],
      },
    }
    const promise = UserApi.getUsersByName(courseId, 'students', searchTerm)

    return promise.then(() => {
      strictEqual(getStub.callCount, 1)
      strictEqual(getStub.firstCall.args[0], url)
      deepEqual(getStub.firstCall.args[1], params)
    })
  })

  test('getUsersByName does not restrict results by enrollment state if passed an empty array', function () {
    const searchTerm = 'Norval'
    const url = `/api/v1/courses/${courseId}/users`
    const params = {
      params: {
        search_term: searchTerm,
        enrollment_type: ['student', 'student_view'],
        enrollment_state: [],
      },
    }
    const promise = UserApi.getUsersByName(courseId, 'students', searchTerm, [])

    return promise.then(() => {
      strictEqual(getStub.callCount, 1)
      strictEqual(getStub.firstCall.args[0], url)
      deepEqual(getStub.firstCall.args[1], params)
    })
  })

  test('getUsersNextPage makes a request with given url', function () {
    const url = 'https://example.com/users?page=2'
    const promise = UserApi.getUsersNextPage(url)

    return promise.then(() => {
      strictEqual(getStub.callCount, 1)
      strictEqual(getStub.firstCall.args[0], url)
    })
  })
})
