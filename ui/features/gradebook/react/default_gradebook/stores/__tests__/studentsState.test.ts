/*
 * Copyright (C) 2022 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute test and/or modify test under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that test will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import store from '../index'
import {clearPrefetchedXHRs, getPrefetchedXHR, setPrefetchedXHR} from '@canvas/util/xhr'
import {RequestDispatch} from '@canvas/network'
import PerformanceControls from '../../PerformanceControls'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {getUsers} from '../graphql/users/getUsers'
import {
  getSubmissions,
  GetSubmissionsParams,
  Submission,
} from '../graphql/submissions/getSubmissions'
import {encode} from '../graphql/buildGraphQLQuery'
import fakeENV from '@canvas/test-utils/fakeENV'

// Helper function to validate student data loading
const verifyStudentDataLoaded = () => {
  expect(store.getState().isStudentDataLoaded).toStrictEqual(true)
  expect(store.getState().isSubmissionDataLoaded).toStrictEqual(true)
  expect(store.getState().studentIds).toMatchObject(['1101', '1102', '1103'])
  expect(store.getState().recentlyLoadedStudents).toMatchObject([{id: '1103'}])
  expect(store.getState().recentlyLoadedSubmissions).toMatchObject([
    {
      submissions: [
        {
          assignment_id: '2301',
          score: 9,
          user_id: '1103',
        },
      ],
      user_id: '1103',
    },
  ])
  expect(store.getState().studentList).toMatchObject([{id: '1101'}, {id: '1102'}, {id: '1103'}])
  expect(store.getState().studentMap).toMatchObject({
    1101: {id: '1101'},
    1102: {id: '1102'},
    1103: {id: '1103'},
  })
  expect(store.getState().assignmentUserSubmissionMap).toStrictEqual({
    '2301': {
      '1101': {
        assignment_id: '2301',
        score: 7,
        user_id: '1101',
      },
      '1102': {
        assignment_id: '2301',
        score: 8,
        user_id: '1102',
      },
      '1103': {
        assignment_id: '2301',
        score: 9,
        user_id: '1103',
      },
    },
  })
}

jest.mock('../graphql/users/getUsers', () => {
  const actual = jest.requireActual('../graphql/users/getUsers')
  return {
    ...actual,
    getUsers: jest.fn(),
  }
})

jest.mock('../graphql/enrollments/getEnrollments', () => {
  const actual = jest.requireActual('../graphql/enrollments/getEnrollments')
  return {
    ...actual,
    getEnrollments: jest.fn().mockResolvedValue({
      course: {
        enrollmentsConnection: {
          nodes: [],
          pageInfo: {
            hasNextPage: false,
            endCursor: '',
          },
        },
      },
    }),
  }
})

jest.mock('../graphql/users/transformUser', () => ({
  transformUser: jest.fn(user => ({id: user._id})),
}))

jest.mock('../graphql/submissions/getSubmissions', () => {
  const actual = jest.requireActual('../graphql/submissions/getSubmissions')
  return {
    ...actual,
    getSubmissions: jest.fn(),
  }
})

jest.mock('../graphql/submissions/transformSubmission', () => ({
  transformSubmission: jest.fn(submission => ({
    assignment_id: submission.assignmentId,
    score: submission.score,
    user_id: submission.userId,
  })),
}))

const initialState = store.getState()

const exampleData = {
  finalGradeOverrides: {
    1101: {
      courseGrade: {
        percentage: 91.23,
      },
    },
  },

  studentIds: ['1101', '1102', '1103'],
  students: [{id: '1101'}, {id: '1102'}, {id: '1103'}],
  submissions: [
    {
      user_id: '1101',
      submissions: [{assignment_id: '2301', score: 7, user_id: '1101'}],
    },
    {
      user_id: '1102',
      submissions: [{assignment_id: '2301', score: 8, user_id: '1102'}],
    },
    {
      user_id: '1103',
      submissions: [{assignment_id: '2301', score: 9, user_id: '1103'}],
    },
  ],
}

const urls = {
  studentIds: '/courses/0/gradebook/user_ids',
  students: '/api/v1/courses/0/users',
  submissions: '/api/v1/courses/0/students/submissions',
}

describe('Gradebook > fetchStudentIds', () => {
  const url = '/courses/*/gradebook/user_ids'
  const server = setupServer()
  const capturedRequests: any[] = []

  let exampleData_: {studentIds: string[]}

  beforeAll(() => {
    server.listen()
  })

  beforeEach(() => {
    fakeENV.setup()
    jest.useRealTimers()
    capturedRequests.length = 0
    exampleData_ = {
      studentIds: ['1101', '1102', '1103'],
    }
  })

  afterEach(() => {
    server.resetHandlers()
    store.setState(initialState, true)
    jest.useFakeTimers()
    fakeENV.teardown()
  })

  afterAll(() => {
    server.close()
  })

  describe('#fetchStudentIds()', () => {
    function getRequestsForUserIds() {
      return capturedRequests.filter(request => {
        return request.url.includes('/user_ids')
      })
    }

    test('sends the request using the given course id', async () => {
      server.use(
        http.get(url, async ({request}) => {
          capturedRequests.push({url: request.url})
          return HttpResponse.json({user_ids: exampleData_.studentIds})
        }),
      )

      await store.getState().fetchStudentIds()
      const requests = getRequestsForUserIds()
      expect(requests).toHaveLength(1)
    })

    describe('when student ids have been prefetched', () => {
      beforeEach(() => {
        fakeENV.setup()
        jest.useRealTimers()
        const jsonString = JSON.stringify({user_ids: exampleData_.studentIds})
        const response = new Response(jsonString)
        setPrefetchedXHR('user_ids', Promise.resolve(response))
      })

      afterEach(() => {
        clearPrefetchedXHRs()
        jest.useFakeTimers()
        fakeENV.teardown()
      })

      test('does not send a request for student ids', async () => {
        server.use(
          http.get(url, async ({request}) => {
            capturedRequests.push({url: request.url})
            return HttpResponse.json({user_ids: exampleData_.studentIds})
          }),
        )

        await store.getState().fetchStudentIds()
        const requests = getRequestsForUserIds()
        expect(requests).toHaveLength(0)
      })

      test('removes the prefetch request', async () => {
        await store.getState().fetchStudentIds()
        expect(typeof getPrefetchedXHR('user_ids')).toStrictEqual('undefined')
      })
    })
  })
})

describe('#loadStudentData()', () => {
  beforeEach(() => {
    fakeENV.setup()
    jest.useRealTimers()
    store.setState({loadCompositeStudentData: jest.fn(), loadGraphqlStudentData: jest.fn()})
  })

  afterEach(() => {
    store.setState(initialState, true)
    jest.useFakeTimers()
    fakeENV.teardown()
  })

  it('calls loadCompositeStudentData if useGraphQL is false', async () => {
    await store.getState().loadStudentData(false)
    expect(store.getState().loadCompositeStudentData).toHaveBeenCalledTimes(1)
    expect(store.getState().loadGraphqlStudentData).not.toHaveBeenCalled()
  })

  it('calls loadGraphqlStudentData if useGraphQL is true', async () => {
    await store.getState().loadStudentData(true)
    expect(store.getState().loadGraphqlStudentData).toHaveBeenCalledTimes(1)
    expect(store.getState().loadCompositeStudentData).not.toHaveBeenCalled()
  })
})

describe('#loadCompositeStudentData()', () => {
  const server = setupServer()

  beforeAll(() => {
    server.listen()
  })

  beforeEach(() => {
    fakeENV.setup()
    jest.useRealTimers()
    const performanceControls = new PerformanceControls({
      studentsChunkSize: 2,
      submissionsChunkSize: 2,
    })

    const dispatch = new RequestDispatch({
      activeRequestLimit: performanceControls.activeRequestLimit,
    })

    store.setState({performanceControls, dispatch, courseId: '0'})

    server.use(
      http.get(urls.studentIds, () => {
        return HttpResponse.json({user_ids: exampleData.studentIds})
      }),
      http.get(urls.students, ({request}) => {
        const url = new URL(request.url)
        const userIds = url.searchParams.getAll('user_ids[]').join(',')
        if (userIds === exampleData.studentIds.slice(0, 2).join(',')) {
          return HttpResponse.json(exampleData.students.slice(0, 2))
        } else if (userIds === exampleData.studentIds.slice(2, 3).join(',')) {
          return HttpResponse.json(exampleData.students.slice(2, 3))
        }
        return HttpResponse.json([])
      }),
      http.get(urls.submissions, ({request}) => {
        const url = new URL(request.url)
        const studentIds = url.searchParams.getAll('student_ids[]').join(',')
        if (studentIds === exampleData.studentIds.slice(0, 2).join(',')) {
          return HttpResponse.json(exampleData.submissions.slice(0, 2))
        } else if (studentIds === exampleData.studentIds.slice(2, 3).join(',')) {
          return HttpResponse.json(exampleData.submissions.slice(2, 3))
        }
        return HttpResponse.json([])
      }),
    )
  })

  afterEach(() => {
    server.resetHandlers()
    store.setState(initialState, true)
    jest.useFakeTimers()
    fakeENV.teardown()
  })

  afterAll(() => {
    server.close()
  })

  test('returns student and submission data', async () => {
    await store.getState().loadCompositeStudentData()
    verifyStudentDataLoaded()
  })
})

describe('#loadGraphqlStudentData()', () => {
  const server = setupServer()
  const mockUsers = [{id: '1101'}, {id: '1102'}, {id: '1103'}]

  beforeAll(() => {
    server.listen()
  })

  beforeEach(() => {
    fakeENV.setup()
    jest.useRealTimers()
    ;(getUsers as jest.Mock).mockImplementation((params: {after?: string}) => {
      const firstPage = mockUsers.slice(0, 2)
      const secondPage = mockUsers.slice(2, 3)
      let res = null

      if (params.after === '') {
        res = {
          course: {
            usersConnection: {
              nodes: firstPage.map(it => ({_id: it.id})),
              pageInfo: {hasNextPage: true, endCursor: 'cursor-0-end'},
            },
          },
        }
      } else {
        res = {
          course: {
            usersConnection: {
              nodes: secondPage.map(it => ({_id: it.id})),
              pageInfo: {hasNextPage: false, endCursor: 'cursor-1-end'},
            },
          },
        }
      }
      return Promise.resolve(res)
    })
    ;(getSubmissions as jest.Mock).mockImplementation(({userIds}: GetSubmissionsParams) => {
      const res: Awaited<ReturnType<typeof getSubmissions>> = {course: {}}

      userIds.forEach(userId => {
        const nodes = (
          exampleData.submissions.find(it => userId === it.user_id)?.submissions ?? []
        ).map(it => ({
          assignmentId: it.assignment_id,
          score: it.score,
          userId: it.user_id,
        })) as unknown as Submission[]
        if (nodes) {
          const alias = encode(userId)
          res.course[alias] = {
            nodes,
            pageInfo: {
              hasNextPage: false,
              endCursor: '',
            },
          }
        }
      })
      return Promise.resolve(res)
    })

    const performanceControls = new PerformanceControls({
      studentsChunkSize: 2,
      submissionsChunkSize: 2,
    })

    const dispatch = new RequestDispatch({
      activeRequestLimit: performanceControls.activeRequestLimit,
    })

    store.setState({performanceControls, dispatch, courseId: '0'})

    server.use(
      http.get(urls.studentIds, () => {
        return HttpResponse.json({user_ids: exampleData.studentIds})
      }),
    )
  })

  afterEach(() => {
    jest.resetAllMocks()
    server.resetHandlers()
    store.setState(initialState, true)
    jest.useFakeTimers()
    fakeENV.teardown()
  })

  afterAll(() => {
    server.close()
  })

  test('returns student and submission data', async () => {
    await store.getState().loadGraphqlStudentData()
    verifyStudentDataLoaded()
  })
})
