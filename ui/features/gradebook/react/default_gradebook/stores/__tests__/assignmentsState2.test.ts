/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

// NOTE: This test suite was copied from `assignmentsState.test.ts`.
// It must remain in a separate file to avoid flaky behavior caused by
// mocking `getAllAssignmentGroups` and `getAllAssignments` in the same context.

import store from '../index'
import {AssignmentGroup as GraphAssignmentGroup} from '../graphql/assignmentGroups/getAssignmentGroups'
import {getAllAssignments} from '../graphql/assignments/getAllAssignments'
import {flatten} from 'lodash'
import {getAllAssignmentGroups} from '../graphql/assignmentGroups/getAllAssignmentGroups'
import {GetAssignmentsParams} from '../graphql/assignments/getAssignments'

jest.mock('../../Gradebook.utils', () => {
  const actual = jest.requireActual('../../Gradebook.utils')
  return {
    ...actual,
    maxAssignmentCount: jest.fn(actual.maxAssignmentCount),
  }
})

jest.mock('../graphql/assignmentGroups/getAllAssignmentGroups', () => ({
  getAllAssignmentGroups: jest.fn(),
}))

jest.mock('../graphql/assignments/getAllAssignments', () => ({
  getAllAssignments: jest.fn(),
}))

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

const GET_ALL_ASSIGNMENT_GROUPS_RESPONSE: GraphAssignmentGroup[] = exampleData.assignmentGroups.map(
  it => ({
    _id: it.id,
    name: it.name,
    position: it.position,
    groupWeight: it.group_weight,
    rules: {
      dropHighest: it.rules.drop_highest ?? null,
      dropLowest: it.rules.drop_lowest ?? null,
      neverDrop: it.rules.never_drop ?? null,
    },
    sisId: null,
    integraionData: null,
  }),
)

const createGetAllAssignmentsResponse = ({
  assignmentGroupId,
  gradingPeriodId,
}: Pick<GetAssignmentsParams, 'assignmentGroupId' | 'gradingPeriodId'>) => {
  let data = flatten(
    exampleData.assignmentGroups
      .filter(group => group.id === assignmentGroupId)
      .map(group => group.assignments),
  )
  if (gradingPeriodId && gradingPeriodId in exampleData.gradingPeriodAssignments) {
    data = data.filter(
      assignment =>
        assignment.id in
        exampleData.gradingPeriodAssignments[
          // keyof cast is checked in the condition
          gradingPeriodId as keyof typeof exampleData.gradingPeriodAssignments
        ],
    )
  }
  return data.map(it => ({
    _id: it.id,
    name: it.name,
    pointsPossible: it.points_possible,
    submissionTypes: it.submission_types,
    muted: it.muted,
    htmlUrl: it.html_url,
    dueAt: it.due_at,
    assignmentGroupId: it.assignment_group_id,
    omitFromFinalGrade: it.omit_from_final_grade,
    published: it.published,
  }))
}

describe('Gradebook', () => {
  describe('fetchAssignmentGroups', () => {
    beforeEach(() => {
      store.setState({courseId: '1201'})
      ;(getAllAssignmentGroups as jest.Mock).mockResolvedValue({
        data: [],
      })
      ;(getAllAssignments as jest.Mock).mockResolvedValue({data: []})
    })
    afterEach(() => {
      jest.resetAllMocks()
      store.setState(initialState, true)
    })

    it.each([true, false])(
      'sets loading state flags correctly during fetch when useGraphQL is %s',
      async value => {
        // Initial state check
        expect(store.getState().isAssignmentGroupsLoading).toBe(false)

        // Start the request
        store.getState().fetchAssignmentGroups({
          params: {
            include: ['assignments'],
            override_assignment_dates: false,
            hide_zero_point_quizzes: false,
            exclude_response_fields: ['description'],
            exclude_assignment_submission_types: ['wiki_page'],
            per_page: 50,
          },
          useGraphQL: value,
        })

        // Check loading state was set synchronously
        expect(store.getState().isAssignmentGroupsLoading).toBe(true)
      },
    )

    it('calls fetchCompositeAssignmentGroups when useGraphQL is false', async () => {
      // Mock fetchCompositeAssignmentGroups to verify it's called
      const mockFetchCompositeAssignmentGroups = jest.fn()
      store.setState({fetchCompositeAssignmentGroups: mockFetchCompositeAssignmentGroups})

      await store.getState().fetchAssignmentGroups({
        params: {} as any,
        useGraphQL: false,
      })

      // Verify fetchCompositeAssignmentGroups was called
      expect(mockFetchCompositeAssignmentGroups).toHaveBeenCalledTimes(1)
    })

    it('calls fetchGrapqhlAssignmentGroups when useGraphQL is true', async () => {
      // Mock fetchCompositeAssignmentGroups to verify it's called
      const mockFetchGrapqhlAssignmentGroups = jest.fn()
      store.setState({fetchGrapqhlAssignmentGroups: mockFetchGrapqhlAssignmentGroups})

      await store.getState().fetchAssignmentGroups({
        params: {} as any,
        useGraphQL: true,
      })

      // Verify fetchCompositeAssignmentGroups was called
      expect(mockFetchGrapqhlAssignmentGroups).toHaveBeenCalledTimes(1)
    })
  })

  describe('fetchGrapqhlAssignmentGroups', () => {
    beforeEach(() => {
      store.setState({courseId: '1201'})
      ;(getAllAssignmentGroups as jest.Mock).mockResolvedValue({
        data: GET_ALL_ASSIGNMENT_GROUPS_RESPONSE,
      })
      ;(getAllAssignments as jest.Mock).mockImplementation(
        ({
          queryParams: {assignmentGroupId, gradingPeriodId},
        }: {queryParams: Pick<GetAssignmentsParams, 'assignmentGroupId' | 'gradingPeriodId'>}) => {
          return Promise.resolve({
            data: createGetAllAssignmentsResponse({assignmentGroupId, gradingPeriodId}),
          })
        },
      )
    })

    afterEach(() => {
      jest.resetAllMocks()
      store.setState(initialState, true)
    })

    it('calls getAllAssignmentGroups with courseId', async () => {
      await store.getState().fetchGrapqhlAssignmentGroups({})
      expect(getAllAssignmentGroups).toHaveBeenCalledTimes(1)
      expect(getAllAssignmentGroups).toHaveBeenCalledWith({
        queryParams: {courseId: '1201'},
      })
    })

    it('calls getAllAssignments with correct parameters', async () => {
      await store.getState().fetchGrapqhlAssignmentGroups({})
      expect(getAllAssignments).toHaveBeenCalledTimes(2)
      expect((getAllAssignments as jest.Mock).mock.calls[0][0]).toEqual({
        queryParams: {assignmentGroupId: 'ag1', gradingPeriodId: null},
      })
      expect((getAllAssignments as jest.Mock).mock.calls[1][0]).toEqual({
        queryParams: {assignmentGroupId: 'ag2', gradingPeriodId: null},
      })
    })

    it('calls getAllAssignments with all grading periods', async () => {
      await store.getState().fetchGrapqhlAssignmentGroups({gradingPeriodIds: ['g1', 'g2']})
      expect(getAllAssignments).toHaveBeenCalledTimes(4)
      expect((getAllAssignments as jest.Mock).mock.calls[0][0]).toEqual({
        queryParams: {assignmentGroupId: 'ag1', gradingPeriodId: 'g1'},
      })
      expect((getAllAssignments as jest.Mock).mock.calls[1][0]).toEqual({
        queryParams: {assignmentGroupId: 'ag1', gradingPeriodId: 'g2'},
      })
      expect((getAllAssignments as jest.Mock).mock.calls[2][0]).toEqual({
        queryParams: {assignmentGroupId: 'ag2', gradingPeriodId: 'g1'},
      })
      expect((getAllAssignments as jest.Mock).mock.calls[3][0]).toEqual({
        queryParams: {assignmentGroupId: 'ag2', gradingPeriodId: 'g2'},
      })
    })

    it('transforms returned objects', async () => {
      const res = await store.getState().fetchGrapqhlAssignmentGroups({})

      // transform assignment adds a lot of noise, lets compare without first
      expect(res.map(it => ({...it, assignments: []}))).toEqual(
        exampleData.assignmentGroups.map(it => ({...it, assignments: []})),
      )
      exampleData.assignmentGroups.forEach((group, i) => {
        group.assignments.forEach((assignment, j) => {
          expect(res[i].assignments[j]).toMatchObject(assignment)
        })
      })
    })
  })
})
