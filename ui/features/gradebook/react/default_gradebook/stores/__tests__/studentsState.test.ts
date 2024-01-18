// @ts-nocheck
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
import FakeServer from '@canvas/network/NaiveRequestDispatch/__tests__/FakeServer'
import {NetworkFake} from '@canvas/network/NetworkFake/index'

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
  const url = '/courses/0/gradebook/user_ids'

  let exampleData_
  let network

  beforeEach(() => {
    exampleData_ = {
      studentIds: ['1101', '1102', '1103'],
    }
  })

  describe('#fetchStudentIds()', () => {
    beforeEach(() => {
      network = new NetworkFake()
    })

    afterEach(() => {
      network.restore()
      store.setState(initialState, true)
    })

    function fetchStudentIds() {
      store.getState().fetchStudentIds()
      return network.allRequestsReady()
    }

    function getRequestsForUserIds() {
      return network.getRequests().filter(request => {
        return request.url === url
      })
    }

    test('sends the request using the given course id', async () => {
      await fetchStudentIds()
      const requests = getRequestsForUserIds()
      expect(requests.length).toStrictEqual(1)
    })

    describe('when student ids have been prefetched', () => {
      beforeEach(() => {
        const jsonString = JSON.stringify({user_ids: exampleData_.studentIds})
        const response = new Response(jsonString)
        setPrefetchedXHR('user_ids', Promise.resolve(response))
      })

      afterEach(() => {
        clearPrefetchedXHRs()
      })

      test('does not send a request for student ids', async () => {
        await fetchStudentIds()
        const requests = getRequestsForUserIds()
        expect(requests.length).toStrictEqual(0)
      })

      test('removes the prefetch request', async () => {
        await fetchStudentIds()
        expect(typeof getPrefetchedXHR('user_ids')).toStrictEqual('undefined')
      })
    })
  })
})

describe('#loadStudentData()', () => {
  let server

  beforeEach(() => {
    const performanceControls = new PerformanceControls({
      studentsChunkSize: 2,
      submissionsChunkSize: 2,
    })

    const dispatch = new RequestDispatch({
      activeRequestLimit: performanceControls.activeRequestLimit,
    })

    store.setState({performanceControls, dispatch})

    server = new FakeServer()
    server.for(urls.studentIds).respond({status: 200, body: {user_ids: exampleData.studentIds}})
    server
      .for(urls.students, {user_ids: exampleData.studentIds.slice(0, 2)})
      .respond([{status: 200, body: exampleData.students.slice(0, 2)}])
    server
      .for(urls.students, {user_ids: exampleData.studentIds.slice(2, 3)})
      .respond({status: 200, body: exampleData.students.slice(2, 3)})
    server
      .for(urls.submissions, {student_ids: exampleData.studentIds.slice(0, 2)})
      .respond([{status: 200, body: exampleData.submissions.slice(0, 2)}])
    server
      .for(urls.submissions, {student_ids: exampleData.studentIds.slice(2, 3)})
      .respond([{status: 200, body: exampleData.submissions.slice(2, 3)}])
  })

  afterEach(() => {
    server.teardown()
    store.setState(initialState, true)
  })

  test('returns student and submission data', async () => {
    const promise1 = await store.getState().loadStudentData()
    await promise1
    expect(store.getState().isStudentDataLoaded).toStrictEqual(true)
    expect(store.getState().isSubmissionDataLoaded).toStrictEqual(true)
    expect(store.getState().studentIds).toMatchObject(['1101', '1102', '1103'])
    expect(store.getState().recentlyLoadedStudents).toMatchObject([{id: '1103'}])
    expect(store.getState().recentlyLoadedSubmissions).toStrictEqual([
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
  })
})
