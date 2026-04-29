/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import $ from 'jquery'
import {request} from 'graphql-request'
import {StoreApi, UseBoundStore} from 'zustand'
import {GradebookStore} from '..'
import {v4 as uuidv4} from 'uuid'

// Mock graphql-request to capture headers
vi.mock('graphql-request', () => ({
  request: vi.fn(),
}))

vi.mock('uuid', () => ({
  v4: vi.fn(),
}))

const TEST_CORRELATION_ID = '8c1e6e8b-4f57-4e9a-bd4f-0f8c4f28a85b'

// Store original implementation
const originalAjax = $.ajax

describe.skip('Gradebook Store - Correlation ID Headers', () => {
  const mockRequest = request as unknown as ReturnType<typeof vi.fn>
  const mockAjax = vi.fn()
  let store: UseBoundStore<StoreApi<GradebookStore>>

  // Helper to verify GraphQL correlation header
  const expectGraphQLCorrelationHeader = () => {
    expect(mockRequest).toHaveBeenCalledWith(
      expect.any(String),
      expect.any(Object),
      expect.any(Object),
      expect.objectContaining({
        'Correlation-Id': TEST_CORRELATION_ID,
      }),
    )
  }

  // Helper to verify REST correlation header
  const expectRESTCorrelationHeader = () => {
    expect(mockAjax).toHaveBeenCalledWith(
      expect.objectContaining({
        headers: expect.objectContaining({
          'Correlation-Id': TEST_CORRELATION_ID,
        }),
      }),
    )
  }

  beforeEach(() => {
    // Use fake timers for runAllTimers
    vi.useFakeTimers()

    // Reset mocks
    mockAjax.mockReset()
    mockRequest.mockReset?.()
    mockRequest.mockResolvedValue?.(undefined)

    // Replace jQuery.ajax with mock (ajaxJSON will use this internally)
    $.ajax = mockAjax

    // Mock successful responses for ajax with promise-like interface
    const mockPromise = {
      then: vi.fn().mockReturnThis(),
      fail: vi.fn().mockReturnThis(),
      always: vi.fn().mockImplementation(callback => {
        callback()
        return mockPromise
      }),
    }
    mockAjax.mockReturnValue(mockPromise)

    // Mock successful GraphQL responses
    mockRequest.mockResolvedValue?.({
      course: {
        assignmentGroupsConnection: {nodes: [], pageInfo: {endCursor: null, hasNextPage: false}},
        usersConnection: {nodes: [], pageInfo: {endCursor: null, hasNextPage: false}},
        enrollmentsConnection: {nodes: [], pageInfo: {endCursor: null, hasNextPage: false}},
      },
    })
    ;(uuidv4 as ReturnType<typeof vi.fn>).mockReturnValue(TEST_CORRELATION_ID)

    store = require('../index').default
  })

  afterEach(() => {
    // Restore original implementation and timers
    $.ajax = originalAjax
    vi.useRealTimers()
  })

  describe('Store Initialization', () => {
    it('should generate a correlation ID when the store is created', () => {
      expect(store.getState().correlationId).toBe(TEST_CORRELATION_ID)
    })
  })

  describe('REST API Requests', () => {
    it('should include Correlation-Id header when fetching assignment groups via REST', async () => {
      const params = {
        include: ['assignments'],
        per_page: 50,
        override_assignment_dates: false,
        hide_zero_point_quizzes: false,
        exclude_response_fields: [],
        exclude_assignment_submission_types: [],
      }

      store.getState().fetchCompositeAssignmentGroups({params})
      vi.runAllTimers()

      expectRESTCorrelationHeader()
    })

    it('should include Correlation-Id header when fetching students via REST', () => {
      const {getStudentsChunk} = require('../studentsState.utils')

      getStudentsChunk('123', ['1', '2'], store.getState().dispatch, TEST_CORRELATION_ID)
      vi.runAllTimers()

      expectRESTCorrelationHeader()
    })

    it('should include Correlation-Id header when fetching submissions via REST', () => {
      const {getSubmissionsForStudents} = require('../studentsState.utils')

      const allEnqueued = Promise.resolve()
      getSubmissionsForStudents(
        50,
        '123',
        ['1', '2'],
        allEnqueued,
        store.getState().dispatch,
        TEST_CORRELATION_ID,
      )
      vi.runAllTimers()

      expectRESTCorrelationHeader()
    })
  })

  describe('GraphQL API Requests', () => {
    it('should include Correlation-Id header when fetching assignment groups via GraphQL', async () => {
      await store.getState().fetchGrapqhlAssignmentGroups({gradingPeriodIds: null})
      vi.runAllTimers()

      expectGraphQLCorrelationHeader()
    })

    it('should include Correlation-Id header when fetching assignments via GraphQL', async () => {
      // Set up store with assignment groups to trigger assignment fetching
      store.setState({
        assignmentGroups: [
          {
            id: 'ag1',
            name: 'Assignment Group 1',
            position: 1,
            group_weight: 0,
            sis_source_id: null,
            rules: {},
            assignments: [],
            integration_data: null,
          },
        ],
      })

      await store.getState().fetchGrapqhlAssignmentGroups({gradingPeriodIds: ['gp1']})
      vi.runAllTimers()

      expectGraphQLCorrelationHeader()
    })

    it('should include Correlation-Id header when fetching users via GraphQL', async () => {
      const {getAllUsers} = require('../graphql/users/getAllUsers')

      await getAllUsers({
        queryParams: {
          userIds: ['1', '2'],
          courseId: '123',
          first: 50,
        },
        headers: {'Correlation-Id': TEST_CORRELATION_ID},
      })
      vi.runAllTimers()

      expectGraphQLCorrelationHeader()
    })

    it('should include Correlation-Id header when fetching enrollments via GraphQL', async () => {
      const {getAllEnrollments} = require('../graphql/enrollments/getAllEnrollments')

      await getAllEnrollments({
        queryParams: {
          userIds: ['1', '2'],
          courseId: '123',
        },
        headers: {'Correlation-Id': TEST_CORRELATION_ID},
      })
      vi.runAllTimers()

      expectGraphQLCorrelationHeader()
    })

    it('should include Correlation-Id header when fetching submissions via GraphQL', async () => {
      const {getAllSubmissions} = require('../graphql/submissions/getAllSubmissions')

      await getAllSubmissions({
        queryParams: {
          userIds: ['1', '2'],
          courseId: '123',
        },
        headers: {'Correlation-Id': TEST_CORRELATION_ID},
      })
      vi.runAllTimers()

      expectGraphQLCorrelationHeader()
    })
  })
})
