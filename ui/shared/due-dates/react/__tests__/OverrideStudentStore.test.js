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
import OverrideStudentStore from '../OverrideStudentStore'
import fakeENV from '@canvas/test-utils/fakeENV'
import sinon from 'sinon'

describe('OverrideStudentStore', () => {
  let server
  let response
  let response2

  beforeEach(() => {
    OverrideStudentStore.reset()
    fakeENV.setup()
    global.ENV = {context_asset_string: 'course_1'}
    server = sinon.createFakeServer()
    response = [
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
    response2 = [
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
  })

  afterEach(() => {
    server.restore()
    OverrideStudentStore.reset()
    fakeENV.teardown()
  })

  function setupServerResponses() {
    server.respondWith(
      'GET',
      '/api/v1/courses/1/users?user_ids=2%2C5%2C8&enrollment_type=student&include%5B%5D=enrollments&include%5B%5D=group_ids',
      [200, {'Content-Type': 'application/json'}, JSON.stringify(response)],
    )
    server.respondWith(
      'GET',
      '/api/v1/courses/1/users?user_ids=2%2C5%2C8%2C7%2C9&enrollment_type=student&include%5B%5D=enrollments&include%5B%5D=group_ids',
      [
        200,
        {
          'Content-Type': 'application/json',
          Link: '<http://page2>; rel="next"',
        },
        JSON.stringify(response),
      ],
    )
    server.respondWith('GET', 'http://page2', [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(response2),
    ])
    server.respondWith('GET', '/api/v1/courses/1/search_users', [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(response),
    ])
    server.respondWith(
      'GET',
      '/api/v1/courses/1/search_users?search_term=publiu&enrollment_type=student&include_inactive=false&include%5B%5D=enrollments&include%5B%5D=group_ids',
      [200, {'Content-Type': 'application/json'}, JSON.stringify(response)],
    )
    server.respondWith('GET', '/api/v1/courses/1/search_users?search_term=publiu', [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(response),
    ])
    server.respondWith(
      'GET',
      '/api/v1/courses/1/users?per_page=50&enrollment_type=student&include_inactive=false&include%5B%5D=enrollments&include%5B%5D=group_ids',
      [
        200,
        {
          'Content-Type': 'application/json',
          Link: '<http://coursepage2>; rel="next"',
        },
        JSON.stringify(response),
      ],
    )
  }

  test('returns students', () => {
    setupServerResponses()
    const someArbitraryVal = 'foo'
    OverrideStudentStore.setState({students: someArbitraryVal})
    expect(OverrideStudentStore.getStudents()).toEqual(someArbitraryVal)
  })

  test('can properly fetch by ID', () => {
    setupServerResponses()
    OverrideStudentStore.fetchStudentsByID([2, 5, 8])
    server.respond()
    expect(server.requests[0].status).toBe(200)
    const results = _.map(OverrideStudentStore.getStudents(), student => student.id)
    expect(results).toEqual(['2', '5', '8'])
  })

  test('does not fetch by ID if no IDs given', () => {
    setupServerResponses()
    OverrideStudentStore.fetchStudentsByID([])
    expect(server.requests).toHaveLength(0)
  })

  test('fetching by id: includes sections on the students', () => {
    setupServerResponses()
    OverrideStudentStore.fetchStudentsByID([2, 5, 8])
    server.respond()
    const sections = _.map(OverrideStudentStore.getStudents(), student => student.sections)
    expect(sections).toEqual([['2'], ['4'], ['4']])
  })

  test('fetching by id: includes group_ids on the students', () => {
    setupServerResponses()
    OverrideStudentStore.fetchStudentsByID([2, 5, 8])
    server.respond()
    const groups = _.map(OverrideStudentStore.getStudents(), student => student.group_ids)
    expect(groups).toEqual([['1', '9'], ['3'], ['4']])
  })

  test('fetching by id: fetches multiple pages if necessary', () => {
    setupServerResponses()
    OverrideStudentStore.fetchStudentsByID([2, 5, 8, 7, 9])
    server.respond()
    expect(server.requests).toHaveLength(2)
    expect(server.queue).toHaveLength(1)
    server.respond()
    expect(server.requests).toHaveLength(2)
    expect(server.queue).toHaveLength(0)
    const results = _.map(OverrideStudentStore.getStudents(), student => student.id)
    expect(results).toEqual(['2', '5', '7', '8', '9'])
  })

  test('can properly fetch a student by name', () => {
    setupServerResponses()
    OverrideStudentStore.fetchStudentsByName('publiu')
    server.respond()
    expect(server.requests[0].status).toBe(200)
  })

  test('sets currentlySearching properly', () => {
    setupServerResponses()
    expect(OverrideStudentStore.currentlySearching()).toBe(false)
    OverrideStudentStore.fetchStudentsByName('publiu')
    expect(OverrideStudentStore.currentlySearching()).toBe(true)
    server.respond()
    expect(OverrideStudentStore.currentlySearching()).toBe(false)
  })

  test('fetches students by same name only once', () => {
    setupServerResponses()
    OverrideStudentStore.fetchStudentsByName('publiu')
    server.respond()
    OverrideStudentStore.fetchStudentsByName('publiu')
    expect(server.requests).toHaveLength(1)
  })

  test('does not fetch if allStudentsFetched is true', () => {
    setupServerResponses()
    OverrideStudentStore.setState({allStudentsFetched: true})
    OverrideStudentStore.fetchStudentsByName('Mike Jones')
    expect(server.requests).toHaveLength(0)
  })

  test('fetching by name: includes sections on the students', () => {
    setupServerResponses()
    OverrideStudentStore.fetchStudentsByName('publiu')
    server.respond()
    const sections = _.map(OverrideStudentStore.getStudents(), student => student.sections)
    expect(sections).toEqual([['2'], ['4'], ['4']])
  })

  test('fetching by name: includes group_ids on the students', () => {
    setupServerResponses()
    OverrideStudentStore.fetchStudentsByName('publiu')
    server.respond()
    const groups = _.map(OverrideStudentStore.getStudents(), student => student.group_ids)
    expect(groups).toEqual([['1', '9'], ['3'], ['4']])
  })

  test('can properly fetch by course', () => {
    setupServerResponses()
    OverrideStudentStore.fetchStudentsForCourse()
    expect(server.requests).toHaveLength(1)
    server.respond()
    expect(server.requests[0].status).toBe(200)
  })

  test('fetching by course: follows pagination up to the limit', () => {
    setupServerResponses()
    OverrideStudentStore.fetchStudentsForCourse()
    server.respond()
    for (let i = 2; i <= 10; i++) {
      server.respondWith('GET', `http://coursepage${i}`, [
        200,
        {
          'Content-Type': 'application/json',
          Link: `<http://coursepage${i + 1}>; rel=\"next\"`,
        },
        '[]',
      ])
      server.respond()
    }
    expect(server.requests).toHaveLength(4)
    expect(OverrideStudentStore.allStudentsFetched()).toBe(false)
  })

  test('fetching by course: saves results from all pages', () => {
    setupServerResponses()
    server.respondWith('GET', 'http://coursepage2', [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(response2),
    ])
    OverrideStudentStore.fetchStudentsForCourse()
    server.respond()
    server.respond()
    const results = _.map(OverrideStudentStore.getStudents(), student => student.id)
    expect(results).toEqual(['2', '5', '7', '8', '9'])
  })

  test('fetching by course: if all users returned, sets allStudentsFetched to true', () => {
    setupServerResponses()
    server.respondWith('GET', 'http://coursepage2', [
      200,
      {'Content-Type': 'application/json'},
      '[]',
    ])
    expect(OverrideStudentStore.allStudentsFetched()).toBe(false)
    OverrideStudentStore.fetchStudentsForCourse()
    server.respond()
    server.respond()
    expect(OverrideStudentStore.allStudentsFetched()).toBe(true)
  })

  test('fetching by course: includes sections on the students', () => {
    setupServerResponses()
    OverrideStudentStore.fetchStudentsForCourse()
    server.respond()
    const sections = _.map(OverrideStudentStore.getStudents(), student => student.sections)
    expect(sections).toEqual([['2'], ['4'], ['4']])
  })

  test('fetching by course: includes group_ids on the students', () => {
    setupServerResponses()
    OverrideStudentStore.fetchStudentsForCourse()
    server.respond()
    const groups = _.map(OverrideStudentStore.getStudents(), student => student.group_ids)
    expect(groups).toEqual([['1', '9'], ['3'], ['4']])
  })

  test('fetching by course: shows secondary info for students with matching names (ignoring case)', () => {
    setupServerResponses()
    server.respondWith('GET', 'http://coursepage2', [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(response2),
    ])
    OverrideStudentStore.fetchStudentsForCourse()
    server.respond()
    server.respond()
    const matching = Object.values(OverrideStudentStore.getStudents())
      .filter(student => ['5', '8', '9'].includes(student.id))
      .map(student => student.displayName)

    expect(matching).toEqual([
      'Publius Scipio (scippy)',
      'Publius Scipio (scipio@example.com)',
      'publius Scipio (pscips08)',
    ])
  })

  test('fetching by course: does not show secondary info if there is no secondary id content', () => {
    response[2].email = null
    setupServerResponses()
    server.respondWith('GET', 'http://coursepage2', [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(response2),
    ])
    OverrideStudentStore.fetchStudentsForCourse()
    server.respond()
    server.respond()
    const matching = Object.values(OverrideStudentStore.getStudents())
      .filter(student => ['5', '8', '9'].includes(student.id))
      .map(student => student.displayName)

    expect(matching).toEqual([
      'Publius Scipio (scippy)',
      'Publius Scipio',
      'publius Scipio (pscips08)',
    ])
  })

  test('fetching by course: does not show secondary info if the same student is returned more than once', () => {
    setupServerResponses()
    server.respondWith('GET', 'http://coursepage2', [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(response2),
    ])
    OverrideStudentStore.fetchStudentsForCourse()
    server.respond()
    server.respond()
    const matching = Object.values(OverrideStudentStore.getStudents())
      .map(student => student.displayName)
      .filter(name => name.includes('Publicola'))

    expect(matching).toEqual(['Publius Publicola'])
  })

  test('ignores punctuation, case, and leading/trailing spaces when comparing student names', () => {
    response[1].name = 'pu@bliüß!%&*) (Scîpiœ '
    response[2].name = 'Publiüß Scîpiœ'
    response2[2].name = ' !Pu%bliüß *scîpiœ&'
    setupServerResponses()
    server.respondWith('GET', 'http://coursepage2', [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(response2),
    ])
    OverrideStudentStore.fetchStudentsForCourse()
    server.respond()
    server.respond()
    const matching = Object.values(OverrideStudentStore.getStudents())
      .filter(student => ['5', '8', '9'].includes(student.id))
      .map(student => student.displayName)

    expect(matching).toEqual([
      'pu@bliüß!%&*) (Scîpiœ  (scippy)',
      'Publiüß Scîpiœ (scipio@example.com)',
      ' !Pu%bliüß *scîpiœ& (pscips08)',
    ])
  })

  test('does not rename students more than once', () => {
    response[1].sis_user_id = '@!'
    setupServerResponses()
    server.respondWith('GET', 'http://coursepage2', [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(response2),
    ])
    OverrideStudentStore.fetchStudentsForCourse()
    server.respond()
    server.respond()
    const matching = Object.values(OverrideStudentStore.getStudents())
      .filter(student => ['5', '8', '9'].includes(student.id))
      .map(student => student.displayName)

    expect(matching).toEqual([
      'Publius Scipio (@!)',
      'Publius Scipio (scipio@example.com)',
      'publius Scipio (pscips08)',
    ])
  })
})
