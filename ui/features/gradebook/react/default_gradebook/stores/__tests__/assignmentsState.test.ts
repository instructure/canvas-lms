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

import {NetworkFake} from '@canvas/network/NetworkFake/index'
import store from '../index'
import {AssignmentLoaderParams, normalizeGradingPeriodId} from '../assignmentsState'
import {RequestDispatch} from '@canvas/network'
import FakeServer from '@canvas/network/NaiveRequestDispatch/__tests__/FakeServer'
import {clearPrefetchedXHRs, getPrefetchedXHR, setPrefetchedXHR} from '@canvas/util/xhr'
import PerformanceControls from '../../PerformanceControls'
import {maxAssignmentCount} from '../../Gradebook.utils'
import {Assignment, AssignmentGroup, AssignmentMap} from 'api'

jest.mock('../../Gradebook.utils', () => {
  const actual = jest.requireActual('../../Gradebook.utils')
  return {
    ...actual,
    maxAssignmentCount: jest.fn(actual.maxAssignmentCount),
  }
})

const initialState = store.getState()

const exampleData = {
  gradingPeriodAssignments: {
    g1: ['a1'],
    g2: ['a2'],
    none: ['a3'],
  },
  assignmentGroups: [
    {
      id: 'ag1',
      name: 'Assignment Group 1',
      position: 1,
      group_weight: 100,
      rules: {drop_highest: undefined, drop_lowest: undefined, never_drop: undefined},
      integration_data: null,
      sis_source_id: null,
      assignments: [
        {
          id: 'a1',
          name: 'Assignment 1',
          points_possible: 10,
          submission_types: ['online_text_entry'],
          muted: false,
          html_url: 'http://www.example.com/courses/1201/assignments/1',
          due_at: '2015-05-18T06:59:00Z',
          assignment_group_id: 'ag1',
          omit_from_final_grade: false,
          published: true,
        },
      ],
    },
    {
      id: 'ag2',
      name: 'Assignment Group 2',
      position: 2,
      group_weight: 100,
      rules: {drop_highest: undefined, drop_lowest: undefined, never_drop: undefined},
      integration_data: null,
      sis_source_id: null,
      assignments: [
        {
          id: 'a2',
          name: 'Assignment 2',
          points_possible: 10,
          submission_types: ['online_quiz'],
          muted: false,
          html_url: 'http://www.example.com/courses/1201/assignments/2',
          due_at: '2015-05-19T06:59:00Z',
          assignment_group_id: 'ag2',
          omit_from_final_grade: false,
          published: true,
        },
        {
          id: 'a3',
          name: 'Assignment 3',
          points_possible: 10,
          submission_types: ['online_text_entry'],
          muted: false,
          html_url: 'http://www.example.com/courses/1201/assignments/3',
          due_at: '2015-05-20T06:59:00Z',
          assignment_group_id: 'ag2',
          omit_from_final_grade: false,
          published: true,
        },
      ],
    },
  ],
}

const urls = {
  gradingPeriodAssignmentsUrl: '/courses/1201/gradebook/grading_period_assignments',
  assignmentGroupsUrl: '/api/v1/courses/1201/assignment_groups',
}

describe('Gradebook', () => {
  describe('normalizeGradingPeriodId', () => {
    it('returns null when input is "0"', () => {
      expect(normalizeGradingPeriodId('0')).toBe(null)
    })

    it('returns the input unchanged for all other values', () => {
      expect(normalizeGradingPeriodId('g1')).toBe('g1')
      expect(normalizeGradingPeriodId('123')).toBe('123')
      expect(normalizeGradingPeriodId(undefined)).toBe(undefined)
    })
  })

  describe('fetchGradingPeriodAssignments', () => {
    let network: NetworkFake

    beforeEach(() => {
      network = new NetworkFake()
      const performanceControls = new PerformanceControls()

      const dispatch = new RequestDispatch({
        activeRequestLimit: performanceControls.activeRequestLimit,
      })
      store.setState({dispatch, courseId: '1201', performanceControls})
    })

    afterEach(() => {
      network.restore()
      jest.resetAllMocks()
      store.setState(initialState, true)
    })

    it('send the requests with the correct course id', async () => {
      store.getState().fetchGradingPeriodAssignments()
      await network.allRequestsReady()

      const requests = network.getRequests()

      expect(requests).toHaveLength(1)
      expect(requests[0].url).toBe(urls.gradingPeriodAssignmentsUrl)
    })

    it('sets loading state immediately and updates after response', async () => {
      // Initial state check
      expect(store.getState().gradingPeriodAssignments).toEqual({})
      expect(store.getState().isGradingPeriodAssignmentsLoading).toBe(false)

      // Start the request
      store.getState().fetchGradingPeriodAssignments()
      const promise = network.allRequestsReady()

      // Check loading state was set synchronously
      expect(store.getState().isGradingPeriodAssignmentsLoading).toBe(true)

      const requests = network.getRequests()

      // Get the request and respond with data
      const [request] = requests
      request.response.setJson({
        grading_period_assignments: exampleData.gradingPeriodAssignments,
      })
      request.response.send()

      // Wait for promise to resolve
      await promise

      // Check final state after response
      expect(store.getState().isGradingPeriodAssignmentsLoading).toBe(false)
      expect(store.getState().gradingPeriodAssignments).toEqual(
        exampleData.gradingPeriodAssignments,
      )
    })

    it('adds a flash message and clears loading state when the request fails', async () => {
      store.setState({flashMessages: [], isGradingPeriodAssignmentsLoading: false})

      // Start the request
      store.getState().fetchGradingPeriodAssignments()
      const promise = network.allRequestsReady()

      // Check loading state was set synchronously
      expect(store.getState().isGradingPeriodAssignmentsLoading).toBe(true)

      const [request] = network.getRequests()

      // Simulate a 500 server error
      request.response.setStatus(500)
      request.response.send()

      // Wait for promise to resolve
      await promise

      // // Verify loading state is cleared
      expect(store.getState().isGradingPeriodAssignmentsLoading).toBe(false)

      // // Verify flash message was added
      expect(store.getState().flashMessages).toHaveLength(1)
      expect(store.getState().flashMessages[0]).toMatchObject({
        key: 'grading-period-assignments-loading-error',
        variant: 'error',
      })
    })

    describe('consume prefetched', () => {
      beforeEach(() => {
        const jsonString = JSON.stringify({
          grading_period_assignments: exampleData.gradingPeriodAssignments,
        })
        const response = new Response(jsonString)
        setPrefetchedXHR('grading_period_assignments', Promise.resolve(response))
      })

      afterEach(() => {
        clearPrefetchedXHRs()
      })

      it('retrieves prefetched data', async () => {
        await store.getState().fetchGradingPeriodAssignments()
        expect(store.getState().isGradingPeriodAssignmentsLoading).toBe(false)
        expect(store.getState().gradingPeriodAssignments).toEqual(
          exampleData.gradingPeriodAssignments,
        )
      })

      it('does not send a request for student ids', async () => {
        await store.getState().fetchGradingPeriodAssignments()
        expect(network.getRequests()).toHaveLength(0)
      })

      it('removes the prefetch request', async () => {
        await store.getState().fetchGradingPeriodAssignments()
        expect(typeof getPrefetchedXHR('grading_period_assignments')).toStrictEqual('undefined')
      })
    })

    describe('non-prefetched path', () => {
      beforeEach(() => {
        // Ensure no prefetched data exists
        clearPrefetchedXHRs()
      })

      it('fetches data from the API when no prefetched data exists', async () => {
        // Mock dispatch.getJSON to return the expected data
        const dispatch = store.getState().dispatch
        const mockGetJSON = jest.fn().mockResolvedValue({
          grading_period_assignments: exampleData.gradingPeriodAssignments,
        })

        // Only modify the dispatch object
        dispatch.getJSON = mockGetJSON

        // Call the function
        await store.getState().fetchGradingPeriodAssignments()

        // Verify getJSON was called with the correct URL
        expect(mockGetJSON).toHaveBeenCalledWith(urls.gradingPeriodAssignmentsUrl)

        // Verify state was updated correctly
        expect(store.getState().gradingPeriodAssignments).toEqual(
          exampleData.gradingPeriodAssignments,
        )
      })

      it('handles network errors correctly with non-prefetched data', async () => {
        // Mock dispatch.getJSON to simulate a network error
        const dispatch = store.getState().dispatch
        const mockGetJSON = jest.fn().mockRejectedValue(new Error('Network error'))

        // Only modify the dispatch object
        dispatch.getJSON = mockGetJSON

        store.setState({flashMessages: []})

        // Call the function
        await store.getState().fetchGradingPeriodAssignments()

        // Verify flash message was added
        expect(store.getState().flashMessages).toHaveLength(1)
        expect(store.getState().flashMessages[0]).toMatchObject({
          key: 'grading-period-assignments-loading-error',
          variant: 'error',
        })

        // Verify state was handled correctly
        expect(store.getState().gradingPeriodAssignments).toEqual({})
        expect(store.getState().isGradingPeriodAssignmentsLoading).toBe(false)
      })
    })
  })

  describe('loadAssignmentGroups', () => {
    let server: FakeServer

    beforeEach(() => {
      const performanceControls = new PerformanceControls({
        studentsChunkSize: 2,
        submissionsChunkSize: 2,
        assignmentGroupsPerPage: 50,
      })

      const dispatch = new RequestDispatch({
        activeRequestLimit: performanceControls.activeRequestLimit,
      })

      store.setState({
        performanceControls,
        dispatch,
        courseId: '1201',
        gradingPeriodAssignments: exampleData.gradingPeriodAssignments,
      })

      server = new FakeServer()
      server
        .for(urls.assignmentGroupsUrl)
        .respond({status: 200, body: exampleData.assignmentGroups})
    })

    afterEach(() => {
      server.teardown()
      jest.resetAllMocks()
      store.setState(initialState, true)
    })

    it.each([false, true])('forwards useGraphQL parameter: %s', async value => {
      // Mock fetchAssignmentGroups to verify parameters
      const mockFetchAssignmentGroups = jest.fn()
      store.setState({
        courseId: '1201',
        hasModules: true,
        fetchAssignmentGroups: mockFetchAssignmentGroups,
      })

      await store.getState().loadAssignmentGroups({hideZeroPointQuizzes: false, useGraphQL: value})

      // Verify fetchAssignmentGroups was called with expected parameters
      expect(mockFetchAssignmentGroups).toHaveBeenCalledTimes(1)
      const [{useGraphQL}] = mockFetchAssignmentGroups.mock.calls[0]
      expect(useGraphQL).toBe(value)
    })

    it('sends request with correct parameters when no grading period is selected', async () => {
      // Mock fetchAssignmentGroups to verify parameters
      const mockFetchAssignmentGroups = jest.fn()
      store.setState({
        courseId: '1201',
        hasModules: true,
        fetchAssignmentGroups: mockFetchAssignmentGroups,
      })

      await store.getState().loadAssignmentGroups({hideZeroPointQuizzes: false, useGraphQL: false})

      // Verify fetchAssignmentGroups was called with expected parameters
      expect(mockFetchAssignmentGroups).toHaveBeenCalledTimes(1)
      const [{params}] = mockFetchAssignmentGroups.mock.calls[0]

      expect(params).toMatchObject({
        include: expect.arrayContaining([
          'assignment_group_id',
          'assignment_visibility',
          'assignments',
          'grades_published',
          'post_manually',
          'checkpoints',
          'has_rubric',
          'module_ids', // This should be included because hasModules is true
        ]),
        hide_zero_point_quizzes: false,
        exclude_assignment_submission_types: ['wiki_page'],
      })
    })

    it('sends request with hide_zero_point_quizzes parameter when specified', async () => {
      // Mock fetchAssignmentGroups to verify parameters
      const mockFetchAssignmentGroups = jest.fn()
      store.setState({
        courseId: '1201',
        hasModules: false,
        fetchAssignmentGroups: mockFetchAssignmentGroups,
      })

      await store.getState().loadAssignmentGroups({hideZeroPointQuizzes: true, useGraphQL: false})

      // Verify fetchAssignmentGroups was called with correct hide_zero_point_quizzes parameter
      const [{params}] = mockFetchAssignmentGroups.mock.calls[0]
      expect(params.hide_zero_point_quizzes).toBe(true)
      // module_ids should not be included since hasModules is false
      expect(params.include).not.toContain('module_ids')
    })

    it('calls loadAssignmentGroupsForGradingPeriods when a valid grading period is selected', async () => {
      // Mock loadAssignmentGroupsForGradingPeriods to verify it's called
      const mockLoadForGradingPeriods = jest.fn()
      store.setState({
        courseId: '1201',
        hasModules: false,
        loadAssignmentGroupsForGradingPeriods: mockLoadForGradingPeriods,
      })

      await store.getState().loadAssignmentGroups({
        hideZeroPointQuizzes: false,
        currentGradingPeriodId: 'g1',
        useGraphQL: false,
      })

      // Verify loadAssignmentGroupsForGradingPeriods was called with correct parameters
      expect(mockLoadForGradingPeriods).toHaveBeenCalledTimes(1)
      const [{params, selectedPeriodId}] = mockLoadForGradingPeriods.mock.calls[0]

      expect(params).toMatchObject({
        include: expect.arrayContaining([
          'assignment_group_id',
          'assignment_visibility',
          'assignments',
          'grades_published',
          'post_manually',
          'checkpoints',
          'has_rubric',
        ]),
        hide_zero_point_quizzes: false,
      })
      expect(selectedPeriodId).toBe('g1')
    })

    it('normalizes grading period id of "0" to null and calls fetchAssignmentGroups directly', async () => {
      // Mock both functions to check which one is called
      const mockLoadForGradingPeriods = jest.fn()
      const mockFetchAssignmentGroups = jest.fn()

      store.setState({
        courseId: '1201',
        hasModules: false,
        loadAssignmentGroupsForGradingPeriods: mockLoadForGradingPeriods,
        fetchAssignmentGroups: mockFetchAssignmentGroups,
      })

      await store.getState().loadAssignmentGroups({
        hideZeroPointQuizzes: false,
        currentGradingPeriodId: '0',
        useGraphQL: false,
      })

      // loadAssignmentGroupsForGradingPeriods should not be called
      expect(mockLoadForGradingPeriods).not.toHaveBeenCalled()

      // fetchAssignmentGroups should be called directly
      expect(mockFetchAssignmentGroups).toHaveBeenCalledTimes(1)
    })

    it('includes module_ids in parameters when hasModules is true', async () => {
      // Mock fetchAssignmentGroups to verify parameters
      const mockFetchAssignmentGroups = jest.fn()
      store.setState({
        courseId: '1201',
        hasModules: true, // Set hasModules to true
        fetchAssignmentGroups: mockFetchAssignmentGroups,
      })

      await store.getState().loadAssignmentGroups({hideZeroPointQuizzes: false, useGraphQL: false})

      // Verify fetchAssignmentGroups was called with include containing module_ids
      const [{params}] = mockFetchAssignmentGroups.mock.calls[0]
      expect(params.include).toContain('module_ids')
    })

    it('does not include module_ids in parameters when hasModules is false', async () => {
      // Mock fetchAssignmentGroups to verify parameters
      const mockFetchAssignmentGroups = jest.fn()
      store.setState({
        courseId: '1201',
        hasModules: false, // Set hasModules to false
        fetchAssignmentGroups: mockFetchAssignmentGroups,
      })

      await store.getState().loadAssignmentGroups({hideZeroPointQuizzes: false, useGraphQL: false})

      // Verify fetchAssignmentGroups was called with include NOT containing module_ids
      const [{params}] = mockFetchAssignmentGroups.mock.calls[0]
      expect(params.include).not.toContain('module_ids')
    })

    it('stores assignment groups data in state after successful fetch', async () => {
      // Set up a full integration test using the FakeServer
      store.setState({
        courseId: '1201',
        hasModules: false,
        assignmentGroups: [],
        assignmentList: [],
        assignmentMap: {},
      })

      // Call the real function
      await store.getState().loadAssignmentGroups({hideZeroPointQuizzes: false, useGraphQL: false})

      // Verify state was updated correctly
      expect(store.getState().assignmentGroups).toEqual(exampleData.assignmentGroups)

      // Check that assignment list and map were populated
      const allAssignments = exampleData.assignmentGroups.flatMap(group => group.assignments)
      expect(store.getState().assignmentList).toHaveLength(allAssignments.length)

      // Verify each assignment is in the map
      allAssignments.forEach(assignment => {
        expect(store.getState().assignmentMap[assignment.id]).toBeDefined()
      })
    })
  })

  describe('loadAssignmentGroupsForGradingPeriods', () => {
    let server: FakeServer

    beforeEach(() => {
      const performanceControls = new PerformanceControls({
        studentsChunkSize: 2,
        submissionsChunkSize: 2,
        assignmentGroupsPerPage: 50,
      })

      const dispatch = new RequestDispatch({
        activeRequestLimit: performanceControls.activeRequestLimit,
      })

      store.setState({
        performanceControls,
        dispatch,
        courseId: '1201',
        gradingPeriodAssignments: exampleData.gradingPeriodAssignments,
      })

      server = new FakeServer()
      server
        .for(urls.assignmentGroupsUrl)
        .respond({status: 200, body: exampleData.assignmentGroups})
    })

    afterEach(() => {
      store.setState(initialState, true)
      jest.resetAllMocks()
      server.teardown()
    })

    const createParams = (): AssignmentLoaderParams => ({
      include: ['assignments'],
      override_assignment_dates: false,
      hide_zero_point_quizzes: false,
      exclude_response_fields: ['description'],
      exclude_assignment_submission_types: ['wiki_page'],
      per_page: store.getState().performanceControls.assignmentGroupsPerPage,
    })

    it.each([false, true])('forwards useGraphQL parameter: %s', async value => {
      // Mock fetchAssignmentGroups to verify parameters
      const mockFetchAssignmentGroups = jest.fn()
      store.setState({fetchAssignmentGroups: mockFetchAssignmentGroups})
      const params = createParams()

      await store
        .getState()
        .loadAssignmentGroupsForGradingPeriods({params, selectedPeriodId: 'g1', useGraphQL: value})

      // Verify fetchAssignmentGroups was called with expected parameters
      expect(mockFetchAssignmentGroups).toHaveBeenCalledTimes(2)
      expect(mockFetchAssignmentGroups.mock.calls[0][0].useGraphQL).toBe(value)
      expect(mockFetchAssignmentGroups.mock.calls[1][0].useGraphQL).toBe(value)
    })

    it('calls fetchAssignmentGroups with assignment IDs for the selected grading period', async () => {
      const mockFetchAssignmentGroups = jest.fn()
      const mockHandleAssignmentGroupsResponse = jest.fn()
      store.setState({
        fetchAssignmentGroups: mockFetchAssignmentGroups,
        handleAssignmentGroupsResponse: mockHandleAssignmentGroupsResponse,
      })

      const params = createParams()
      await store
        .getState()
        .loadAssignmentGroupsForGradingPeriods({params, selectedPeriodId: 'g1', useGraphQL: false})

      // Should be called with the assignment IDs from grading period g1
      expect(mockFetchAssignmentGroups).toHaveBeenCalledWith(
        expect.objectContaining({
          params: expect.objectContaining({
            assignment_ids: 'a1', // The assignments in g1
          }),
        }),
      )

      expect(mockHandleAssignmentGroupsResponse).toHaveBeenCalledWith(
        expect.objectContaining({
          isSelectedGradingPeriodId: true,
          gradingPeriodIds: ['g1'],
        }),
      )
    })

    it('calls fetchAssignmentGroups for other grading period assignments too', async () => {
      const mockFetchAssignmentGroups = jest.fn()

      store.setState({
        fetchAssignmentGroups: mockFetchAssignmentGroups,
      })

      await store.getState().loadAssignmentGroupsForGradingPeriods({
        params: createParams(),
        selectedPeriodId: 'g1',
        useGraphQL: false,
      })

      // Should be called twice - once for g1 and once for other assignments
      expect(mockFetchAssignmentGroups).toHaveBeenCalledTimes(2)

      // Second call should be for other assignments (g2 and "none" in our test data)
      const [{params}] = mockFetchAssignmentGroups.mock.calls[0]

      expect(params.assignment_ids).toBe('a2,a3')
    })

    it('falls back to fetching all assignments when selected grading period has too many assignments', async () => {
      const mockFetchAssignmentGroups = jest.fn()
      const mockHandleAssignmentGroupsResponse = jest.fn()
      // Mock maxAssignmentCount to return a small number to trigger the fallback
      ;(maxAssignmentCount as jest.Mock).mockReturnValue(0)

      store.setState({
        fetchAssignmentGroups: mockFetchAssignmentGroups,
        handleAssignmentGroupsResponse: mockHandleAssignmentGroupsResponse,
      })

      await store.getState().loadAssignmentGroupsForGradingPeriods({
        params: createParams(),
        selectedPeriodId: 'g1',
        useGraphQL: false,
      })

      // Should be called once with no assignment_ids parameter
      expect(mockFetchAssignmentGroups).toHaveBeenCalledTimes(1)

      const [{params}] = mockFetchAssignmentGroups.mock.calls[0]
      expect(params.assignment_ids).toBeUndefined()
      expect(mockHandleAssignmentGroupsResponse).toHaveBeenCalledWith(
        expect.objectContaining({isSelectedGradingPeriodId: true}),
      )
    })

    it('falls back to fetching all assignments when selected grading period has no assignments', async () => {
      const mockFetchAssignmentGroups = jest.fn()
      const mockHandleAssignmentGroupsResponse = jest.fn()

      // Set up a grading period with no assignments
      store.setState({
        fetchAssignmentGroups: mockFetchAssignmentGroups,
        handleAssignmentGroupsResponse: mockHandleAssignmentGroupsResponse,
        gradingPeriodAssignments: {
          ...exampleData.gradingPeriodAssignments,
          empty: [],
        },
      })

      await store.getState().loadAssignmentGroupsForGradingPeriods({
        params: createParams(),
        selectedPeriodId: 'empty',
        useGraphQL: false,
      })

      // Should be called once with no assignment_ids parameter
      expect(mockFetchAssignmentGroups).toHaveBeenCalledTimes(1)
      const [{params}] = mockFetchAssignmentGroups.mock.calls[0]
      expect(params.assignment_ids).toBeUndefined()
      expect(mockHandleAssignmentGroupsResponse).toHaveBeenCalledWith(
        expect.objectContaining({isSelectedGradingPeriodId: true}),
      )
    })

    it('handles empty gradingPeriodAssignments object', async () => {
      const mockFetchAssignmentGroups = jest.fn()
      const mockHandleAssignmentGroupsResponse = jest.fn()

      // Set up with empty gradingPeriodAssignments
      store.setState({
        fetchAssignmentGroups: mockFetchAssignmentGroups,
        handleAssignmentGroupsResponse: mockHandleAssignmentGroupsResponse,
        gradingPeriodAssignments: {},
      })

      await store.getState().loadAssignmentGroupsForGradingPeriods({
        params: createParams(),
        selectedPeriodId: 'g1',
        useGraphQL: false,
      })

      // Should fall back to fetching all assignments
      expect(mockFetchAssignmentGroups).toHaveBeenCalledTimes(1)
      const [{params}] = mockFetchAssignmentGroups.mock.calls[0]
      expect(params.assignment_ids).toBeUndefined()
      expect(mockHandleAssignmentGroupsResponse).toHaveBeenCalledWith(
        expect.objectContaining({isSelectedGradingPeriodId: true}),
      )
    })

    it('returns the promise from the selected grading period fetch', async () => {
      const expectedResult = [{id: 'test'}]
      const mockHandleAssignmentGroupsResponse = jest
        .fn()
        .mockImplementation(({isSelectedGradingPeriodId}) => {
          return Promise.resolve(isSelectedGradingPeriodId ? expectedResult : [])
        })

      store.setState({handleAssignmentGroupsResponse: mockHandleAssignmentGroupsResponse})

      const params = createParams()
      const result = await store
        .getState()
        .loadAssignmentGroupsForGradingPeriods({params, selectedPeriodId: 'g1', useGraphQL: false})

      // Should return the result from the first (selected) call
      expect(result).toBe(expectedResult)
    })
  })

  describe('handleAssignmentGroupsResponse', () => {
    afterEach(() => {
      jest.resetAllMocks()
      store.setState(initialState, true)
    })

    it('handles assignment groups with no assignments', async () => {
      // Create assignment groups with empty assignments array
      const assignmentGroupsWithNoAssignments: AssignmentGroup[] = [
        {
          id: 'ag1',
          name: 'Assignment Group 1',
          position: 1,
          group_weight: 100,
          rules: {},
          assignments: [], // Empty assignments array
          integration_data: {},
          sis_source_id: null,
        },
      ]

      await store.getState().handleAssignmentGroupsResponse({
        promise: Promise.resolve(assignmentGroupsWithNoAssignments),
        isSelectedGradingPeriodId: true,
      })

      // Verify state was updated with empty assignments
      expect(store.getState().assignmentGroups).toEqual(assignmentGroupsWithNoAssignments)
      expect(store.getState().assignmentList).toEqual([])
    })

    it('properly merges new assignments into assignmentMap and assignmentList', async () => {
      // Set up initial state with an existing assignment to verify merging behavior
      const existingAssignment = {
        id: 'existing-1',
        name: 'Existing Assignment',
        points_possible: 15,
        submission_types: ['online_text_entry'],
        muted: false,
        html_url: 'http://www.example.com/courses/1201/assignments/existing-1',
        assignment_group_id: 'ag1',
        omit_from_final_grade: false,
        published: true,
      }

      store.setState({
        assignmentMap: {'existing-1': existingAssignment} as unknown as AssignmentMap,
        assignmentList: [existingAssignment] as Assignment[],
        assignmentGroups: [],
      })

      // Execute request
      await store.getState().handleAssignmentGroupsResponse({
        promise: Promise.resolve(exampleData.assignmentGroups) as Promise<AssignmentGroup[]>,
        isSelectedGradingPeriodId: true,
      })

      // Get the flattened list of all assignments from our example data
      const allNewAssignments = exampleData.assignmentGroups.flatMap(group => group.assignments)

      // Verify assignmentMap contains both existing and new assignments
      expect(Object.keys(store.getState().assignmentMap)).toHaveLength(allNewAssignments.length + 1)
      expect(store.getState().assignmentMap['existing-1']).toEqual(existingAssignment)
      allNewAssignments.forEach(assignment => {
        expect(store.getState().assignmentMap[assignment.id]).toBeDefined()
      })

      // Verify assignmentList contains all assignments
      expect(store.getState().assignmentList).toHaveLength(allNewAssignments.length + 1)
      expect(store.getState().assignmentList).toContainEqual(existingAssignment)

      // Verify assignment groups were added to state
      expect(store.getState().assignmentGroups).toEqual(exampleData.assignmentGroups)
    })

    it('sets loading state flags correctly during fetch', async () => {
      store.setState({isAssignmentGroupsLoading: true})
      // Initial state check
      expect(store.getState().isAssignmentGroupsLoading).toBe(true)

      // Wait for promise to resolve
      await store.getState().handleAssignmentGroupsResponse({
        promise: Promise.resolve(exampleData.assignmentGroups) as Promise<AssignmentGroup[]>,
        isSelectedGradingPeriodId: true,
      })

      // Verify loading state is reset when done
      expect(store.getState().isAssignmentGroupsLoading).toBe(false)
    })

    it('sets recentlyLoadedAssignmentGroups when isSelectedGradingPeriodId is true', async () => {
      await store.getState().handleAssignmentGroupsResponse({
        promise: Promise.resolve(exampleData.assignmentGroups) as Promise<AssignmentGroup[]>,
        isSelectedGradingPeriodId: true,
        gradingPeriodIds: ['g1'],
      })

      // Verify recentlyLoadedAssignmentGroups is updated
      expect(store.getState().recentlyLoadedAssignmentGroups).toEqual({
        assignmentGroups: exampleData.assignmentGroups,
        gradingPeriodIds: ['g1'],
      })
    })

    it('does not set recentlyLoadedAssignmentGroups when isSelectedGradingPeriodId is false', async () => {
      // Set initial data
      const initialRecentlyLoaded = {
        assignmentGroups: [],
        gradingPeriodIds: ['test'],
      }

      store.setState({recentlyLoadedAssignmentGroups: initialRecentlyLoaded})

      await store.getState().handleAssignmentGroupsResponse({
        promise: Promise.resolve(exampleData.assignmentGroups) as Promise<AssignmentGroup[]>,
        isSelectedGradingPeriodId: false,
        gradingPeriodIds: ['g2'],
      })

      // Verify recentlyLoadedAssignmentGroups remains unchanged
      expect(store.getState().recentlyLoadedAssignmentGroups).toEqual(initialRecentlyLoaded)
    })

    it('adds a flash message when the request fails', async () => {
      // Initial state check
      expect(store.getState().flashMessages).toHaveLength(0)
      await store.getState().handleAssignmentGroupsResponse({
        promise: Promise.reject(':('),
        isSelectedGradingPeriodId: true,
        gradingPeriodIds: ['g1'],
      })

      // Verify flash message was added
      expect(store.getState().flashMessages).toHaveLength(1)
      expect(store.getState().flashMessages[0]).toMatchObject({
        key: 'assignments-groups-loading-error',
        variant: 'error',
      })
    })

    it('clears loading state even when request fails', async () => {
      // Start with loading state set
      store.setState({isAssignmentGroupsLoading: true})
      expect(store.getState().isAssignmentGroupsLoading).toBe(true)

      // Execute with error
      await store.getState().handleAssignmentGroupsResponse({
        promise: Promise.reject(':('),
        isSelectedGradingPeriodId: true,
        gradingPeriodIds: ['g1'],
      })

      // Verify loading state is reset
      expect(store.getState().isAssignmentGroupsLoading).toBe(false)
    })

    it('handles undefined return from getDepaginated', async () => {
      // Mock dispatch.getDepaginated to return undefined
      store.setState({assignmentGroups: [], assignmentList: [], assignmentMap: {}})

      // Execute the function
      const result = await store.getState().handleAssignmentGroupsResponse({
        promise: Promise.resolve(undefined) as unknown as Promise<AssignmentGroup[]>,
        isSelectedGradingPeriodId: true,
        gradingPeriodIds: ['g1'],
      })

      // Verify result is undefined
      expect(result).toBeUndefined()

      // Verify state remains unchanged
      expect(store.getState().assignmentGroups).toEqual([])
      expect(store.getState().assignmentList).toEqual([])
      expect(Object.keys(store.getState().assignmentMap)).toHaveLength(0)
    })
  })
})
