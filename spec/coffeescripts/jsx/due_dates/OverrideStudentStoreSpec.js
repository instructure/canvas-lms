/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import React from 'react'
import {Simulate, SimulateNative} from 'react-addons-test-utils'
import _ from 'underscore'
import OverrideStudentStore from 'jsx/due_dates/OverrideStudentStore'
import fakeENV from 'helpers/fakeENV'

QUnit.module('OverrideStudentStore', {
  setup() {
    OverrideStudentStore.reset()
    fakeENV.setup()
    ENV.context_asset_string = 'course_1'
    this.server = sinon.fakeServer.create()
    this.response = [
      {
        id: '2',
        name: 'Publius Publicola',
        sortable_name: 'Publicola, Publius',
        short_name: 'Publius',
        group_ids: ['1', '9'],
        enrollments: [
          {
            id: '7',
            course_section_id: '2',
            type: 'StudentEnrollment'
          }
        ]
      },
      {
        id: '5',
        name: 'Publius Scipio',
        sortable_name: 'Scipio, Publius',
        short_name: 'Publius',
        group_ids: ['3'],
        enrollments: [
          {
            id: '8',
            course_section_id: '4',
            type: 'StudentEnrollment'
          }
        ]
      }
    ]
    this.response2 = [
      {
        id: '7',
        name: 'Publius Varus',
        sortable_name: 'Varus, Publius',
        short_name: 'Publius'
      }
    ]
    this.server.respondWith(
      'GET',
      '/api/v1/courses/1/users?user_ids=2%2C5&enrollment_type=student&include%5B%5D=enrollments&include%5B%5D=group_ids',
      [200, {'Content-Type': 'application/json'}, JSON.stringify(this.response)]
    )
    this.server.respondWith(
      'GET',
      '/api/v1/courses/1/users?user_ids=2%2C5%2C7&enrollment_type=student&include%5B%5D=enrollments&include%5B%5D=group_ids',
      [
        200,
        {
          'Content-Type': 'application/json',
          Link: '<http://page2>; rel="next"'
        },
        JSON.stringify(this.response)
      ]
    )
    this.server.respondWith('GET', 'http://page2', [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(this.response2)
    ])
    this.server.respondWith('GET', '/api/v1/courses/1/search_users', [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(this.response)
    ])
    this.server.respondWith(
      'GET',
      '/api/v1/courses/1/search_users?search_term=publiu&enrollment_type=student&include_inactive=false&include%5B%5D=enrollments&include%5B%5D=group_ids',
      [200, {'Content-Type': 'application/json'}, JSON.stringify(this.response)]
    )
    this.server.respondWith('GET', '/api/v1/courses/1/search_users?search_term=publiu', [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(this.response)
    ])
    return this.server.respondWith(
      'GET',
      '/api/v1/courses/1/users?per_page=50&enrollment_type=student&include_inactive=false&include%5B%5D=enrollments&include%5B%5D=group_ids',
      [
        200,
        {
          'Content-Type': 'application/json',
          Link: '<http://coursepage2>; rel="next"'
        },
        JSON.stringify(this.response)
      ]
    )
  },
  teardown() {
    this.server.restore()
    OverrideStudentStore.reset()
    fakeENV.teardown()
  }
})

test('returns students', () => {
  const someArbitraryVal = 'foo'
  OverrideStudentStore.setState({students: someArbitraryVal})
  equal(OverrideStudentStore.getStudents(), someArbitraryVal)
})

test('can properly fetch by ID', function() {
  OverrideStudentStore.fetchStudentsByID([2, 5])
  this.server.respond()
  equal(200, this.server.requests[0].status)
  const results = _.map(OverrideStudentStore.getStudents(), student => student.id)
  deepEqual(results, ['2', '5'])
})

test('does not fetch by ID if no IDs given', function() {
  OverrideStudentStore.fetchStudentsByID([])
  equal(this.server.requests.length, 0)
})

test('fetching by id: includes sections on the students', function() {
  OverrideStudentStore.fetchStudentsByID([2, 5])
  this.server.respond()
  const sections = _.map(OverrideStudentStore.getStudents(), student => student.sections)
  return propEqual(sections, [['2'], ['4']])
})

test('fetching by id: includes group_ids on the students', function() {
  OverrideStudentStore.fetchStudentsByID([2, 5])
  this.server.respond()
  const groups = _.map(OverrideStudentStore.getStudents(), student => student.group_ids)
  return propEqual(groups, [['1', '9'], ['3']])
})

test('fetching by id: fetches multiple pages if necessary', function() {
  OverrideStudentStore.fetchStudentsByID([2, 5, 7])
  this.server.respond()
  equal(this.server.requests.length, 2)
  equal(this.server.queue.length, 1)
  this.server.respond()
  equal(this.server.requests.length, 2)
  equal(this.server.queue.length, 0)
  const results = _.map(OverrideStudentStore.getStudents(), student => student.id)
  deepEqual(results, ['2', '5', '7'])
})

test('can properly fetch a student by name', function() {
  OverrideStudentStore.fetchStudentsByName('publiu')
  this.server.respond()
  equal(200, this.server.requests[0].status)
})

test('sets currentlySearching properly', function() {
  equal(false, OverrideStudentStore.currentlySearching())
  OverrideStudentStore.fetchStudentsByName('publiu')
  equal(true, OverrideStudentStore.currentlySearching())
  this.server.respond()
  equal(false, OverrideStudentStore.currentlySearching())
})

test('fetches students by same name only once', function() {
  OverrideStudentStore.fetchStudentsByName('publiu')
  this.server.respond()
  OverrideStudentStore.fetchStudentsByName('publiu')
  equal(1, this.server.requests.length)
})

test('does not fetch if allStudentsFetched is true', function() {
  OverrideStudentStore.setState({allStudentsFetched: true})
  OverrideStudentStore.fetchStudentsByName('Mike Jones')
  equal(this.server.requests.length, 0)
})

test('fetching by name: includes sections on the students', function() {
  OverrideStudentStore.fetchStudentsByName('publiu')
  this.server.respond()
  const sections = _.map(OverrideStudentStore.getStudents(), student => student.sections)
  return propEqual(sections, [['2'], ['4']])
})

test('fetching by name: includes group_ids on the students', function() {
  OverrideStudentStore.fetchStudentsByName('publiu')
  this.server.respond()
  const groups = _.map(OverrideStudentStore.getStudents(), student => student.group_ids)
  return propEqual(groups, [['1', '9'], ['3']])
})

test('can properly fetch by course', function() {
  OverrideStudentStore.fetchStudentsForCourse()
  equal(this.server.requests.length, 1)
  this.server.respond()
  equal(this.server.requests[0].status, 200)
})

test('fetching by course: follows pagination up to the limit', function() {
  OverrideStudentStore.fetchStudentsForCourse()
  this.server.respond()
  for (let i = 2; i <= 10; i++) {
    this.server.respondWith('GET', `http://coursepage${i}`, [
      200,
      {
        'Content-Type': 'application/json',
        Link: `<http://coursepage${i + 1}>; rel=\"next\"`
      },
      '[]'
    ])
    this.server.respond()
  }
  equal(this.server.requests.length, 4)
  equal(OverrideStudentStore.allStudentsFetched(), false)
})

test('fetching by course: saves results from all pages', function() {
  this.server.respondWith('GET', 'http://coursepage2', [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify(this.response2)
  ])
  OverrideStudentStore.fetchStudentsForCourse()
  this.server.respond()
  this.server.respond()
  const results = _.map(OverrideStudentStore.getStudents(), student => student.id)
  deepEqual(results, ['2', '5', '7'])
})

test('fetching by course: if all users returned, sets allStudentsFetched to true', function() {
  this.server.respondWith('GET', 'http://coursepage2', [
    200,
    {'Content-Type': 'application/json'},
    '[]'
  ])
  equal(OverrideStudentStore.allStudentsFetched(), false)
  OverrideStudentStore.fetchStudentsForCourse()
  this.server.respond()
  this.server.respond()
  equal(OverrideStudentStore.allStudentsFetched(), true)
})

test('fetching by course: includes sections on the students', function() {
  OverrideStudentStore.fetchStudentsForCourse()
  this.server.respond()
  const sections = _.map(OverrideStudentStore.getStudents(), student => student.sections)
  return propEqual(sections, [['2'], ['4']])
})

test('fetching by course: includes group_ids on the students', function() {
  OverrideStudentStore.fetchStudentsForCourse()
  this.server.respond()
  const groups = _.map(OverrideStudentStore.getStudents(), student => student.group_ids)
  return propEqual(groups, [['1', '9'], ['3']])
})
