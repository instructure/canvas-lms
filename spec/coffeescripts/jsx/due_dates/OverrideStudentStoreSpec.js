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

import _ from 'lodash'
import OverrideStudentStore from '@canvas/due-dates/react/OverrideStudentStore'
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
        email: null,
        login_id: 'PubPub23',
        name: 'Publius Publicola',
        sis_user_id: null,
        sortable_name: 'Publicola, Publius',
        short_name: 'Publius',
        group_ids: ['1', '9'],
        enrollments: [
          {
            id: '7',
            course_section_id: '2',
            type: 'StudentEnrollment',
          },
        ],
      },
      {
        id: '5',
        email: null,
        login_id: null,
        name: 'Publius Scipio',
        sis_user_id: 'scippy',
        sortable_name: 'Scipio, Publius',
        short_name: 'Publius',
        group_ids: ['3'],
        enrollments: [
          {
            id: '8',
            course_section_id: '4',
            type: 'StudentEnrollment',
          },
        ],
      },
      {
        id: '8',
        email: 'scipio@example.com',
        login_id: null,
        name: 'Publius Scipio',
        sis_user_id: null,
        sortable_name: 'Scipio, Publius',
        short_name: 'Publius',
        group_ids: ['4'],
        enrollments: [
          {
            id: '10',
            course_section_id: '4',
            type: 'StudentEnrollment',
          },
        ],
      },
    ]
    this.response2 = [
      {
        id: '7',
        email: null,
        login_id: 'varus',
        sis_user_id: null,
        name: 'Publius Varus',
        sortable_name: 'Varus, Publius',
        short_name: 'Publius',
      },
      {
        id: '2',
        email: null,
        login_id: 'PubPub23',
        name: 'Publius Publicola',
        sis_user_id: null,
        sortable_name: 'Publicola, Publius',
        short_name: 'Publius',
        group_ids: ['1', '9'],
        enrollments: [
          {
            id: '7',
            course_section_id: '2',
            type: 'StudentEnrollment',
          },
        ],
      },
      {
        id: '9',
        email: null,
        login_id: 'pscips08',
        name: 'publius Scipio',
        sis_user_id: null,
        sortable_name: 'Scipio, Publius',
        short_name: 'Publius',
        group_ids: ['3'],
        enrollments: [
          {
            id: '9',
            course_section_id: '4',
            type: 'StudentEnrollment',
          },
        ],
      },
    ]
  },
  teardown() {
    this.server.restore()
    OverrideStudentStore.reset()
    fakeENV.teardown()
  },
  setupServerResponses() {
    this.server.respondWith(
      'GET',
      '/api/v1/courses/1/users?user_ids=2%2C5%2C8&enrollment_type=student&include%5B%5D=enrollments&include%5B%5D=group_ids',
      [200, {'Content-Type': 'application/json'}, JSON.stringify(this.response)]
    )
    this.server.respondWith(
      'GET',
      '/api/v1/courses/1/users?user_ids=2%2C5%2C8%2C7%2C9&enrollment_type=student&include%5B%5D=enrollments&include%5B%5D=group_ids',
      [
        200,
        {
          'Content-Type': 'application/json',
          Link: '<http://page2>; rel="next"',
        },
        JSON.stringify(this.response),
      ]
    )
    this.server.respondWith('GET', 'http://page2', [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(this.response2),
    ])
    this.server.respondWith('GET', '/api/v1/courses/1/search_users', [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(this.response),
    ])
    this.server.respondWith(
      'GET',
      '/api/v1/courses/1/search_users?search_term=publiu&enrollment_type=student&include_inactive=false&include%5B%5D=enrollments&include%5B%5D=group_ids',
      [200, {'Content-Type': 'application/json'}, JSON.stringify(this.response)]
    )
    this.server.respondWith('GET', '/api/v1/courses/1/search_users?search_term=publiu', [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(this.response),
    ])
    this.server.respondWith(
      'GET',
      '/api/v1/courses/1/users?per_page=50&enrollment_type=student&include_inactive=false&include%5B%5D=enrollments&include%5B%5D=group_ids',
      [
        200,
        {
          'Content-Type': 'application/json',
          Link: '<http://coursepage2>; rel="next"',
        },
        JSON.stringify(this.response),
      ]
    )
  },
})

test('returns students', function () {
  this.setupServerResponses()
  const someArbitraryVal = 'foo'
  OverrideStudentStore.setState({students: someArbitraryVal})
  equal(OverrideStudentStore.getStudents(), someArbitraryVal)
})

test('can properly fetch by ID', function () {
  this.setupServerResponses()
  OverrideStudentStore.fetchStudentsByID([2, 5, 8])
  this.server.respond()
  equal(this.server.requests[0].status, 200)
  const results = _.map(OverrideStudentStore.getStudents(), student => student.id)
  deepEqual(results, ['2', '5', '8'])
})

test('does not fetch by ID if no IDs given', function () {
  this.setupServerResponses()
  OverrideStudentStore.fetchStudentsByID([])
  equal(this.server.requests.length, 0)
})

test('fetching by id: includes sections on the students', function () {
  this.setupServerResponses()
  OverrideStudentStore.fetchStudentsByID([2, 5, 8])
  this.server.respond()
  const sections = _.map(OverrideStudentStore.getStudents(), student => student.sections)
  return propEqual(sections, [['2'], ['4'], ['4']])
})

test('fetching by id: includes group_ids on the students', function () {
  this.setupServerResponses()
  OverrideStudentStore.fetchStudentsByID([2, 5, 8])
  this.server.respond()
  const groups = _.map(OverrideStudentStore.getStudents(), student => student.group_ids)
  return propEqual(groups, [['1', '9'], ['3'], ['4']])
})

test('fetching by id: fetches multiple pages if necessary', function () {
  this.setupServerResponses()
  OverrideStudentStore.fetchStudentsByID([2, 5, 8, 7, 9])
  this.server.respond()
  equal(this.server.requests.length, 2)
  equal(this.server.queue.length, 1)
  this.server.respond()
  equal(this.server.requests.length, 2)
  equal(this.server.queue.length, 0)
  const results = _.map(OverrideStudentStore.getStudents(), student => student.id)
  deepEqual(results, ['2', '5', '7', '8', '9'])
})

test('can properly fetch a student by name', function () {
  this.setupServerResponses()
  OverrideStudentStore.fetchStudentsByName('publiu')
  this.server.respond()
  equal(200, this.server.requests[0].status)
})

test('sets currentlySearching properly', function () {
  this.setupServerResponses()
  equal(false, OverrideStudentStore.currentlySearching())
  OverrideStudentStore.fetchStudentsByName('publiu')
  equal(true, OverrideStudentStore.currentlySearching())
  this.server.respond()
  equal(false, OverrideStudentStore.currentlySearching())
})

test('fetches students by same name only once', function () {
  this.setupServerResponses()
  OverrideStudentStore.fetchStudentsByName('publiu')
  this.server.respond()
  OverrideStudentStore.fetchStudentsByName('publiu')
  equal(1, this.server.requests.length)
})

test('does not fetch if allStudentsFetched is true', function () {
  this.setupServerResponses()
  OverrideStudentStore.setState({allStudentsFetched: true})
  OverrideStudentStore.fetchStudentsByName('Mike Jones')
  equal(this.server.requests.length, 0)
})

test('fetching by name: includes sections on the students', function () {
  this.setupServerResponses()
  OverrideStudentStore.fetchStudentsByName('publiu')
  this.server.respond()
  const sections = _.map(OverrideStudentStore.getStudents(), student => student.sections)
  return propEqual(sections, [['2'], ['4'], ['4']])
})

test('fetching by name: includes group_ids on the students', function () {
  this.setupServerResponses()
  OverrideStudentStore.fetchStudentsByName('publiu')
  this.server.respond()
  const groups = _.map(OverrideStudentStore.getStudents(), student => student.group_ids)
  return propEqual(groups, [['1', '9'], ['3'], ['4']])
})

test('can properly fetch by course', function () {
  this.setupServerResponses()
  OverrideStudentStore.fetchStudentsForCourse()
  equal(this.server.requests.length, 1)
  this.server.respond()
  equal(this.server.requests[0].status, 200)
})

test('fetching by course: follows pagination up to the limit', function () {
  this.setupServerResponses()
  OverrideStudentStore.fetchStudentsForCourse()
  this.server.respond()
  for (let i = 2; i <= 10; i++) {
    this.server.respondWith('GET', `http://coursepage${i}`, [
      200,
      {
        'Content-Type': 'application/json',
        Link: `<http://coursepage${i + 1}>; rel=\"next\"`,
      },
      '[]',
    ])
    this.server.respond()
  }
  equal(this.server.requests.length, 4)
  equal(OverrideStudentStore.allStudentsFetched(), false)
})

test('fetching by course: saves results from all pages', function () {
  this.setupServerResponses()
  this.server.respondWith('GET', 'http://coursepage2', [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify(this.response2),
  ])
  OverrideStudentStore.fetchStudentsForCourse()
  this.server.respond()
  this.server.respond()
  const results = _.map(OverrideStudentStore.getStudents(), student => student.id)
  deepEqual(results, ['2', '5', '7', '8', '9'])
})

test('fetching by course: if all users returned, sets allStudentsFetched to true', function () {
  this.setupServerResponses()
  this.server.respondWith('GET', 'http://coursepage2', [
    200,
    {'Content-Type': 'application/json'},
    '[]',
  ])
  equal(OverrideStudentStore.allStudentsFetched(), false)
  OverrideStudentStore.fetchStudentsForCourse()
  this.server.respond()
  this.server.respond()
  equal(OverrideStudentStore.allStudentsFetched(), true)
})

test('fetching by course: includes sections on the students', function () {
  this.setupServerResponses()
  OverrideStudentStore.fetchStudentsForCourse()
  this.server.respond()
  const sections = _.map(OverrideStudentStore.getStudents(), student => student.sections)
  return propEqual(sections, [['2'], ['4'], ['4']])
})

test('fetching by course: includes group_ids on the students', function () {
  this.setupServerResponses()
  OverrideStudentStore.fetchStudentsForCourse()
  this.server.respond()
  const groups = _.map(OverrideStudentStore.getStudents(), student => student.group_ids)
  return propEqual(groups, [['1', '9'], ['3'], ['4']])
})

test('fetching by course: shows secondary info for students with matching names (ignoring case)', function () {
  this.setupServerResponses()
  this.server.respondWith('GET', 'http://coursepage2', [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify(this.response2),
  ])
  OverrideStudentStore.fetchStudentsForCourse()
  this.server.respond()
  this.server.respond()
  const matching = Object.values(OverrideStudentStore.getStudents())
    .filter(student => ['5', '8', '9'].includes(student.id))
    .map(student => student.displayName)

  propEqual(matching, [
    'Publius Scipio (scippy)',
    'Publius Scipio (scipio@example.com)',
    'publius Scipio (pscips08)',
  ])
})

test('fetching by course: does not show secondary info if there is no secondary id content', function () {
  this.response[2].email = null
  this.setupServerResponses()
  this.server.respondWith('GET', 'http://coursepage2', [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify(this.response2),
  ])
  OverrideStudentStore.fetchStudentsForCourse()
  this.server.respond()
  this.server.respond()
  const matching = Object.values(OverrideStudentStore.getStudents())
    .filter(student => ['5', '8', '9'].includes(student.id))
    .map(student => student.displayName)

  propEqual(matching, ['Publius Scipio (scippy)', 'Publius Scipio', 'publius Scipio (pscips08)'])
})

test('fetching by course: does not show secondary info if the same student is returned more than once', function () {
  this.setupServerResponses()
  this.server.respondWith('GET', 'http://coursepage2', [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify(this.response2),
  ])
  OverrideStudentStore.fetchStudentsForCourse()
  this.server.respond()
  this.server.respond()
  const matching = Object.values(OverrideStudentStore.getStudents())
    .map(student => student.displayName)
    .filter(name => name.includes('Publicola'))

  propEqual(matching, ['Publius Publicola'])
})

test('ignores punctuation, case, and leading/trailing spaces when comparing student names', function () {
  this.response[1].name = 'pu@bliüß!%&*) (Scîpiœ '
  this.response[2].name = 'Publiüß Scîpiœ'
  this.response2[2].name = ' !Pu%bliüß *scîpiœ&'
  this.setupServerResponses()
  this.server.respondWith('GET', 'http://coursepage2', [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify(this.response2),
  ])
  OverrideStudentStore.fetchStudentsForCourse()
  this.server.respond()
  this.server.respond()
  const matching = Object.values(OverrideStudentStore.getStudents())
    .filter(student => ['5', '8', '9'].includes(student.id))
    .map(student => student.displayName)

  propEqual(matching, [
    'pu@bliüß!%&*) (Scîpiœ  (scippy)',
    'Publiüß Scîpiœ (scipio@example.com)',
    ' !Pu%bliüß *scîpiœ& (pscips08)',
  ])
})

test('does not rename students more than once', function () {
  this.response[1].sis_user_id = '@!'
  this.setupServerResponses()
  this.server.respondWith('GET', 'http://coursepage2', [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify(this.response2),
  ])
  OverrideStudentStore.fetchStudentsForCourse()
  this.server.respond()
  this.server.respond()
  const matching = Object.values(OverrideStudentStore.getStudents())
    .filter(student => ['5', '8', '9'].includes(student.id))
    .map(student => student.displayName)

  propEqual(matching, [
    'Publius Scipio (@!)',
    'Publius Scipio (scipio@example.com)',
    'publius Scipio (pscips08)',
  ])
})
