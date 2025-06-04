/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import CourseRestoreModel from '../CourseRestore'
import $ from 'jquery'
import 'jquery-migrate'

const fixturesDiv = document.createElement('div')
fixturesDiv.id = 'fixtures'
document.body.appendChild(fixturesDiv)

const ok = x => expect(x).toBeTruthy()
const equal = (x, y) => expect(x).toEqual(y)

let account_id
let course_id
let courseRestore
let server
let clock

const progressCompletedJSON = {
  completion: 0,
  context_id: 4,
  context_type: 'Account',
  created_at: '2013-03-08T16:37:46-07:00',
  id: 28,
  message: null,
  tag: 'course_batch_update',
  updated_at: '2013-03-08T16:37:46-07:00',
  url: 'http://localhost:3000/api/v1/progress/28',
  user_id: 51,
  workflow_state: 'completed',
}
const progressQueuedJSON = {
  completion: 0,
  context_id: 4,
  context_type: 'Account',
  created_at: '2013-03-08T16:37:46-07:00',
  id: 28,
  message: null,
  tag: 'course_batch_update',
  updated_at: '2013-03-08T16:37:46-07:00',
  url: 'http://localhost:3000/api/v1/progress/28',
  user_id: 51,
  workflow_state: 'queued',
}
const courseJSON = {
  account_id: 6,
  course_code: 'Super',
  default_view: 'feed',
  end_at: null,
  enrollments: [],
  hide_final_grades: false,
  id: 58,
  name: 'Super Fun Deleted Course',
  sis_course_id: null,
  start_at: null,
  workflow_state: 'deleted',
}

describe('CourseRestore', () => {
  beforeEach(() => {
    account_id = 4
    course_id = 42
    courseRestore = new CourseRestoreModel({account_id})

    // Mock XMLHttpRequest for server
    const xhrMockClass = {
      open: jest.fn(),
      send: jest.fn(),
      setRequestHeader: jest.fn(),
      readyState: 4,
      status: 200,
      responseText: '',
      onreadystatechange: null,
      getAllResponseHeaders: jest.fn().mockReturnValue(''),
      getResponseHeader: jest.fn(),
    }

    window.XMLHttpRequest = jest.fn().mockImplementation(() => xhrMockClass)
    server = {
      requests: [],
      respond: (method, url, response) => {
        const request = server.requests.find(req => req.method === method && req.url === url)
        if (request) {
          request.xhr.status = response[0]
          request.xhr.responseText = response[2]
          request.xhr.readyState = 4
          if (request.xhr.onreadystatechange) {
            request.xhr.onreadystatechange()
          }
        }
      },
    }

    // Override jQuery's ajax to capture requests
    const originalAjax = $.ajax
    jest.spyOn($, 'ajax').mockImplementation(function (options) {
      const xhr = new window.XMLHttpRequest()
      server.requests.push({
        method: options.type || 'GET',
        url: options.url,
        xhr: xhr,
      })

      // Return a promise-like object
      const deferred = $.Deferred()

      xhr.onreadystatechange = function () {
        if (xhr.readyState === 4) {
          if (xhr.status === 200) {
            const data = JSON.parse(xhr.responseText)
            deferred.resolve(data)
            if (options.success) options.success(data)
          } else {
            deferred.reject(xhr)
            if (options.error) options.error(xhr)
          }
        }
      }

      return deferred.promise()
    })

    jest.useFakeTimers()
    return $('#fixtures').append($('<div id="flash_screenreader_holder" />'))
  })

  afterEach(() => {
    jest.restoreAllMocks()
    jest.useRealTimers()
    account_id = null
    $('#fixtures').empty()
  })
  // Describes searching for a course by ID
  test("triggers 'searching' when search is called", function () {
    const callback = jest.fn()
    courseRestore.on('searching', callback)
    courseRestore.search(account_id)
    ok(callback.mock.calls.length > 0, 'Searching event is called when searching')
  })

  test('populates CourseRestore model with response, keeping its original account_id', function () {
    courseRestore.search(course_id)
    server.respond('GET', courseRestore.searchUrl(), [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(courseJSON),
    ])
    equal(courseRestore.get('account_id'), account_id, 'account id stayed the same')
    equal(courseRestore.get('id'), courseJSON.id, 'course id was updated')
  })

  test('set status when course not found', function () {
    courseRestore.search('a')
    server.respond('GET', courseRestore.searchUrl(), [
      404,
      {'Content-Type': 'application/json'},
      JSON.stringify({}),
    ])
    equal(courseRestore.get('status'), 404)
  })

  test('responds with a deferred object', function () {
    const dfd = courseRestore.restore()
    ok($.isFunction(dfd.done, 'This is a deferred object'))
  })

  // a restored course should be populated with a deleted course with an after a search was made.
  test('restores a course after search finds a deleted course', function () {
    courseRestore.search(course_id)
    server.respond('GET', courseRestore.searchUrl(), [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(courseJSON),
    ])
    const dfd = courseRestore.restore()
    server.respond(
      'PUT',
      `${courseRestore.baseUrl()}/?course_ids[]=${courseRestore.get('id')}&event=undelete`,
      [200, {'Content-Type': 'application/json'}, JSON.stringify(progressQueuedJSON)],
    )
    jest.advanceTimersByTime(1000)
    server.respond('GET', progressQueuedJSON.url, [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(progressCompletedJSON),
    ])
    ok(dfd.state() === 'resolved', 'All ajax request in this deferred object should be resolved')
    equal(courseRestore.get('workflow_state'), 'unpublished')
  })
})
