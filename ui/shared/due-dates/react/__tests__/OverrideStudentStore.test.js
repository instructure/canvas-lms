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
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {waitFor} from '@testing-library/dom'

describe('OverrideStudentStore', () => {
  let response
  let response2
  let requestCount = 0

  const server = setupServer()

  beforeAll(() => server.listen())
  afterEach(() => {
    server.resetHandlers()
    requestCount = 0
  })
  afterAll(() => server.close())

  beforeEach(() => {
    OverrideStudentStore.reset()
    fakeENV.setup()
    global.ENV = {context_asset_string: 'course_1'}
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
    OverrideStudentStore.reset()
    fakeENV.teardown()
  })

  function setupServerResponses() {
    server.use(
      http.get('*/api/v1/courses/1/users', ({request}) => {
        const url = new URL(request.url)
        const userIds = url.searchParams.get('user_ids')
        const perPage = url.searchParams.get('per_page')

        if (userIds === '2,5,8') {
          return HttpResponse.json(response)
        } else if (userIds === '2,5,8,7,9') {
          return HttpResponse.json(response, {
            headers: {
              Link: '<http://page2>; rel="next"',
            },
          })
        } else if (perPage === '50') {
          return HttpResponse.json(response, {
            headers: {
              Link: '<http://coursepage2>; rel="next"',
            },
          })
        }
        return HttpResponse.json([])
      }),

      http.get('http://page2', () => {
        return HttpResponse.json(response2)
      }),

      http.get('*/api/v1/courses/1/search_users', ({request}) => {
        const url = new URL(request.url)
        const searchTerm = url.searchParams.get('search_term')

        if (searchTerm === 'publiu' || !searchTerm) {
          return HttpResponse.json(response)
        }
        return HttpResponse.json([])
      }),

      http.get('http://coursepage2', () => {
        requestCount++
        if (requestCount === 1) {
          return HttpResponse.json(response2)
        }
        return HttpResponse.json([])
      }),
    )
  }

  test('returns students', () => {
    setupServerResponses()
    const someArbitraryVal = 'foo'
    OverrideStudentStore.setState({students: someArbitraryVal})
    expect(OverrideStudentStore.getStudents()).toEqual(someArbitraryVal)
  })

  test('can properly fetch by ID', async () => {
    setupServerResponses()
    OverrideStudentStore.fetchStudentsByID([2, 5, 8])
    await waitFor(() => {
      const results = _.map(OverrideStudentStore.getStudents(), student => student.id)
      expect(results).toEqual(['2', '5', '8'])
    })
  })

  test('does not fetch by ID if no IDs given', () => {
    setupServerResponses()
    let requestMade = false
    server.use(
      http.get('*/api/v1/courses/1/users', () => {
        requestMade = true
        return HttpResponse.json([])
      }),
    )
    OverrideStudentStore.fetchStudentsByID([])
    expect(requestMade).toBe(false)
  })

  test('fetching by id: includes sections on the students', async () => {
    setupServerResponses()
    OverrideStudentStore.fetchStudentsByID([2, 5, 8])
    await waitFor(() => {
      const sections = _.map(OverrideStudentStore.getStudents(), student => student.sections)
      expect(sections).toEqual([['2'], ['4'], ['4']])
    })
  })

  test('fetching by id: includes group_ids on the students', async () => {
    setupServerResponses()
    OverrideStudentStore.fetchStudentsByID([2, 5, 8])
    await waitFor(() => {
      const groups = _.map(OverrideStudentStore.getStudents(), student => student.group_ids)
      expect(groups).toEqual([['1', '9'], ['3'], ['4']])
    })
  })

  test('fetching by id: fetches multiple pages if necessary', async () => {
    setupServerResponses()
    OverrideStudentStore.fetchStudentsByID([2, 5, 8, 7, 9])
    await waitFor(() => {
      const results = _.map(OverrideStudentStore.getStudents(), student => student.id)
      expect(results).toEqual(['2', '5', '7', '8', '9'])
    })
  })

  test('can properly fetch a student by name', async () => {
    setupServerResponses()
    OverrideStudentStore.fetchStudentsByName('publiu')
    await waitFor(() => {
      const students = OverrideStudentStore.getStudents()
      expect(Object.keys(students)).toHaveLength(3)
    })
  })

  test('sets currentlySearching properly', async () => {
    setupServerResponses()
    expect(OverrideStudentStore.currentlySearching()).toBe(false)
    OverrideStudentStore.fetchStudentsByName('publiu')
    expect(OverrideStudentStore.currentlySearching()).toBe(true)
    await waitFor(() => {
      expect(OverrideStudentStore.currentlySearching()).toBe(false)
    })
  })

  test('fetches students by same name only once', async () => {
    setupServerResponses()
    let localRequestCount = 0
    server.use(
      http.get('*/api/v1/courses/1/search_users', () => {
        localRequestCount++
        return HttpResponse.json(response)
      }),
    )
    OverrideStudentStore.fetchStudentsByName('publiu')
    await waitFor(() => {
      expect(OverrideStudentStore.currentlySearching()).toBe(false)
    })
    OverrideStudentStore.fetchStudentsByName('publiu')
    expect(localRequestCount).toBe(1)
  })

  test('does not fetch if allStudentsFetched is true', () => {
    setupServerResponses()
    let requestMade = false
    server.use(
      http.get('*/api/v1/courses/1/search_users', () => {
        requestMade = true
        return HttpResponse.json([])
      }),
    )
    OverrideStudentStore.setState({allStudentsFetched: true})
    OverrideStudentStore.fetchStudentsByName('Mike Jones')
    expect(requestMade).toBe(false)
  })

  test('fetching by name: includes sections on the students', async () => {
    setupServerResponses()
    OverrideStudentStore.fetchStudentsByName('publiu')
    await waitFor(() => {
      const sections = _.map(OverrideStudentStore.getStudents(), student => student.sections)
      expect(sections).toEqual([['2'], ['4'], ['4']])
    })
  })

  test('fetching by name: includes group_ids on the students', async () => {
    setupServerResponses()
    OverrideStudentStore.fetchStudentsByName('publiu')
    await waitFor(() => {
      const groups = _.map(OverrideStudentStore.getStudents(), student => student.group_ids)
      expect(groups).toEqual([['1', '9'], ['3'], ['4']])
    })
  })

  test('can properly fetch by course', async () => {
    setupServerResponses()
    OverrideStudentStore.fetchStudentsForCourse()
    await waitFor(() => {
      const students = OverrideStudentStore.getStudents()
      // Should have fetched students from first page and second page
      expect(Object.keys(students).length).toBeGreaterThan(0)
    })
  })

  test('fetching by course: follows pagination up to the limit', async () => {
    setupServerResponses()

    // Override the coursepage handlers to return pages up to 10
    for (let i = 2; i <= 10; i++) {
      server.use(
        http.get(`http://coursepage${i}`, () => {
          return HttpResponse.json([], {
            headers: {
              Link: `<http://coursepage${i + 1}>; rel="next"`,
            },
          })
        }),
      )
    }

    OverrideStudentStore.fetchStudentsForCourse()
    await waitFor(() => {
      expect(OverrideStudentStore.allStudentsFetched()).toBe(false)
    })
  })

  test('fetching by course: saves results from all pages', async () => {
    setupServerResponses()
    server.use(
      http.get('http://coursepage2', () => {
        return HttpResponse.json(response2)
      }),
    )
    OverrideStudentStore.fetchStudentsForCourse()
    await waitFor(() => {
      const results = _.map(OverrideStudentStore.getStudents(), student => student.id)
      expect(results.sort()).toEqual(['2', '5', '7', '8', '9'])
    })
  })

  test('fetching by course: if all users returned, sets allStudentsFetched to true', async () => {
    setupServerResponses()
    server.use(
      http.get('http://coursepage2', () => {
        return HttpResponse.json([])
      }),
    )
    expect(OverrideStudentStore.allStudentsFetched()).toBe(false)
    OverrideStudentStore.fetchStudentsForCourse()
    await waitFor(() => {
      expect(OverrideStudentStore.allStudentsFetched()).toBe(true)
    })
  })

  test('fetching by course: includes sections on the students', async () => {
    setupServerResponses()
    OverrideStudentStore.fetchStudentsForCourse()
    await waitFor(() => {
      const students = OverrideStudentStore.getStudents()
      const studentArray = Object.values(students)
      expect(studentArray.length).toBeGreaterThan(0)
      // Check that all students have sections
      studentArray.forEach(student => {
        expect(student.sections).toBeDefined()
      })
    })
  })

  test('fetching by course: includes group_ids on the students', async () => {
    setupServerResponses()
    OverrideStudentStore.fetchStudentsForCourse()
    await waitFor(() => {
      const students = OverrideStudentStore.getStudents()
      const studentArray = Object.values(students)
      expect(studentArray.length).toBeGreaterThan(0)
      // Check that students with group_ids have them properly set
      const studentsWithGroups = studentArray.filter(s => s.group_ids)
      expect(studentsWithGroups.length).toBeGreaterThan(0)
      studentsWithGroups.forEach(student => {
        expect(Array.isArray(student.group_ids)).toBe(true)
      })
    })
  })

  test('fetching by course: shows secondary info for students with matching names (ignoring case)', async () => {
    setupServerResponses()
    server.use(
      http.get('http://coursepage2', () => {
        return HttpResponse.json(response2)
      }),
    )
    OverrideStudentStore.fetchStudentsForCourse()
    await waitFor(() => {
      const matching = Object.values(OverrideStudentStore.getStudents())
        .filter(student => ['5', '8', '9'].includes(student.id))
        .map(student => student.displayName)

      expect(matching.sort()).toEqual([
        'Publius Scipio (scipio@example.com)',
        'Publius Scipio (scippy)',
        'publius Scipio (pscips08)',
      ])
    })
  })

  test('fetching by course: does not show secondary info if there is no secondary id content', async () => {
    response[2].email = null
    setupServerResponses()
    server.use(
      http.get('http://coursepage2', () => {
        return HttpResponse.json(response2)
      }),
    )
    OverrideStudentStore.fetchStudentsForCourse()
    await waitFor(() => {
      const matching = Object.values(OverrideStudentStore.getStudents())
        .filter(student => ['5', '8', '9'].includes(student.id))
        .map(student => student.displayName)

      expect(matching.sort()).toEqual([
        'Publius Scipio',
        'Publius Scipio (scippy)',
        'publius Scipio (pscips08)',
      ])
    })
  })

  test('fetching by course: does not show secondary info if the same student is returned more than once', async () => {
    setupServerResponses()
    server.use(
      http.get('http://coursepage2', () => {
        return HttpResponse.json(response2)
      }),
    )
    OverrideStudentStore.fetchStudentsForCourse()
    await waitFor(() => {
      const matching = Object.values(OverrideStudentStore.getStudents())
        .map(student => student.displayName)
        .filter(name => name.includes('Publicola'))

      expect(matching).toEqual(['Publius Publicola'])
    })
  })

  test('ignores punctuation, case, and leading/trailing spaces when comparing student names', async () => {
    response[1].name = 'pu@bliüß!%&*) (Scîpiœ '
    response[2].name = 'Publiüß Scîpiœ'
    response2[2].name = ' !Pu%bliüß *scîpiœ&'
    setupServerResponses()
    server.use(
      http.get('http://coursepage2', () => {
        return HttpResponse.json(response2)
      }),
    )
    OverrideStudentStore.fetchStudentsForCourse()
    await waitFor(() => {
      const matching = Object.values(OverrideStudentStore.getStudents())
        .filter(student => ['5', '8', '9'].includes(student.id))
        .map(student => student.displayName)

      expect(matching.sort()).toEqual([
        ' !Pu%bliüß *scîpiœ& (pscips08)',
        'Publiüß Scîpiœ (scipio@example.com)',
        'pu@bliüß!%&*) (Scîpiœ  (scippy)',
      ])
    })
  })

  test('does not rename students more than once', async () => {
    response[1].sis_user_id = '@!'
    setupServerResponses()
    server.use(
      http.get('http://coursepage2', () => {
        return HttpResponse.json(response2)
      }),
    )
    OverrideStudentStore.fetchStudentsForCourse()
    await waitFor(() => {
      const matching = Object.values(OverrideStudentStore.getStudents())
        .filter(student => ['5', '8', '9'].includes(student.id))
        .map(student => student.displayName)

      expect(matching.sort()).toEqual([
        'Publius Scipio (@!)',
        'Publius Scipio (scipio@example.com)',
        'publius Scipio (pscips08)',
      ])
    })
  })
})
