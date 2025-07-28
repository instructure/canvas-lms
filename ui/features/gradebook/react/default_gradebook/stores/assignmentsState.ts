/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import type {StoreApi} from 'zustand'
import {useScope as createI18nScope} from '@canvas/i18n'
import {asJson, consumePrefetchedXHR} from '@canvas/util/xhr'
import {maxAssignmentCount, otherGradingPeriodAssignmentIds} from '../Gradebook.utils'
import type {GradebookStore} from './index'
import type {GradingPeriodAssignmentMap} from '../gradebook.d'
import type {AssignmentGroup, Assignment, AssignmentMap, SubmissionType} from '../../../../../api.d'
import {getAllAssignmentGroups} from './graphql/assignmentGroups/getAllAssignmentGroups'
import {transformAssignmentGroup} from './graphql/assignmentGroups/transformAssignmentGroup'
import {flatten, groupBy, isArray} from 'lodash'
import {getAllAssignments} from './graphql/assignments/getAllAssignments'
import {transformAssignment} from './graphql/assignments/transformAssignments'
import pLimit from 'p-limit'
import GRADEBOOK_GRAPHQL_CONFIG from './graphql/config'

type FetchGradingPeriodAssignmentsResponse = {
  grading_period_assignments: GradingPeriodAssignmentMap
}
type FetchGradingPeriodAssignments = () => Promise<GradingPeriodAssignmentMap | void>

type LoadAssignmentGroupsForGradingPeriodsParams = {
  params: AssignmentLoaderParams
  selectedPeriodId: string
  useGraphQL: boolean
}
type LoadAssignmentGroupsForGradingPeriods = ({
  params,
}: LoadAssignmentGroupsForGradingPeriodsParams) => Promise<AssignmentGroup[] | undefined>

type LoadAssignmentGroupsParams = {
  hideZeroPointQuizzes: boolean
  currentGradingPeriodId?: string
  useGraphQL: boolean
}
type LoadAssignmentGroups = (
  params: LoadAssignmentGroupsParams,
) => Promise<AssignmentGroup[] | undefined>

type FetchAssignmentGroupsParams = {
  params: AssignmentLoaderParams
  gradingPeriodIds?: string[] | null
  useGraphQL: boolean
}
type FetchAssignmentGroups = (params: FetchAssignmentGroupsParams) => Promise<AssignmentGroup[]>

type FetchCompositeAssignmentGroupsParams = {params: AssignmentLoaderParams}
type FetchCompositeAssignmentGroups = (
  params: FetchCompositeAssignmentGroupsParams,
) => Promise<AssignmentGroup[]>

type FetchGrapqhlAssignmentGroupsParams = {gradingPeriodIds?: string[] | null}
type FetchGrapqhlAssignmentGroups = (
  params: FetchGrapqhlAssignmentGroupsParams,
) => Promise<AssignmentGroup[]>

type HandleAssignmentGroupsResponseParams = {
  promise: Promise<AssignmentGroup[]>
  isSelectedGradingPeriodId: boolean
  gradingPeriodIds?: string[]
}
type HandleAssignmentGroupsResponse = (
  params: HandleAssignmentGroupsResponseParams,
) => Promise<AssignmentGroup[] | undefined>

const I18n = createI18nScope('gradebook')

export type AssignmentsState = {
  gradingPeriodAssignments: GradingPeriodAssignmentMap
  isGradingPeriodAssignmentsLoading: boolean
  isAssignmentGroupsLoading: boolean
  fetchGradingPeriodAssignments: FetchGradingPeriodAssignments
  loadAssignmentGroupsForGradingPeriods: LoadAssignmentGroupsForGradingPeriods
  loadAssignmentGroups: LoadAssignmentGroups
  fetchAssignmentGroups: FetchAssignmentGroups
  fetchCompositeAssignmentGroups: FetchCompositeAssignmentGroups
  fetchGrapqhlAssignmentGroups: FetchGrapqhlAssignmentGroups
  handleAssignmentGroupsResponse: HandleAssignmentGroupsResponse
  recentlyLoadedAssignmentGroups: {
    assignmentGroups: AssignmentGroup[]
    gradingPeriodIds?: string[]
  }
  assignmentGroups: AssignmentGroup[]
  assignmentList: Assignment[]
  assignmentMap: AssignmentMap
}

export type AssignmentLoaderParams = {
  include: string[]
  override_assignment_dates: boolean
  hide_zero_point_quizzes: boolean
  exclude_response_fields: string[]
  exclude_assignment_submission_types: SubmissionType[]
  per_page: number
  assignment_ids?: string
}

export const normalizeGradingPeriodId = (id?: string) => (id === '0' ? null : id)

export default (
  set: StoreApi<GradebookStore>['setState'],
  get: StoreApi<GradebookStore>['getState'],
): AssignmentsState => ({
  gradingPeriodAssignments: {},

  isGradingPeriodAssignmentsLoading: false,

  isAssignmentGroupsLoading: false,

  recentlyLoadedAssignmentGroups: {
    assignmentGroups: [],
    gradingPeriodIds: [],
  },

  assignmentGroups: [],

  assignmentList: [],

  assignmentMap: {},

  fetchGradingPeriodAssignments: () => {
    const dispatch = get().dispatch
    const courseId = get().courseId

    set({isGradingPeriodAssignmentsLoading: true})

    /*
     * When user ids have been prefetched, the data is only known valid for the
     * first request. Consume it by pulling it out of the prefetch store, which
     * will force all subsequent requests for user ids to call through the
     * network.
     */
    const prefetched = consumePrefetchedXHR('grading_period_assignments')
    const promise = prefetched
      ? (asJson(prefetched) as Promise<FetchGradingPeriodAssignmentsResponse>)
      : dispatch.getJSON<FetchGradingPeriodAssignmentsResponse>(
          `/courses/${courseId}/gradebook/grading_period_assignments`,
        )

    return promise
      .then(({grading_period_assignments}) => {
        set({
          gradingPeriodAssignments: grading_period_assignments,
          isGradingPeriodAssignmentsLoading: false,
        })
        return grading_period_assignments
      })
      .catch(() => {
        set({
          isGradingPeriodAssignmentsLoading: false,
          flashMessages: get().flashMessages.concat([
            {
              key: 'grading-period-assignments-loading-error',
              message: I18n.t('There was an error fetching grading period assignments data.'),
              variant: 'error',
            },
          ]),
        })
      })
  },

  loadAssignmentGroups: ({hideZeroPointQuizzes = false, currentGradingPeriodId, useGraphQL}) => {
    const include = [
      'assignment_group_id',
      'assignment_visibility',
      'assignments',
      'grades_published',
      'post_manually',
      'checkpoints',
      'has_rubric',
    ]

    if (get().hasModules) {
      include.push('module_ids')
    }

    const params: AssignmentLoaderParams = {
      exclude_assignment_submission_types: ['wiki_page'],
      exclude_response_fields: [
        'description',
        'in_closed_grading_period',
        'needs_grading_count',
        'rubric',
      ],
      include,
      override_assignment_dates: false,
      hide_zero_point_quizzes: hideZeroPointQuizzes,
      per_page: get().performanceControls.assignmentGroupsPerPage,
    }

    const selectedPeriodId = normalizeGradingPeriodId(currentGradingPeriodId)
    if (selectedPeriodId) {
      return get().loadAssignmentGroupsForGradingPeriods({params, selectedPeriodId, useGraphQL})
    }

    return get().handleAssignmentGroupsResponse({
      promise: get().fetchAssignmentGroups({params, useGraphQL}),
      isSelectedGradingPeriodId: true,
    })
  },

  loadAssignmentGroupsForGradingPeriods: ({params, selectedPeriodId, useGraphQL}) => {
    const selectedAssignmentIds: string[] = get().gradingPeriodAssignments[selectedPeriodId] || []

    const {otherAssignmentIds, otherGradingPeriodIds} = otherGradingPeriodAssignmentIds(
      get().gradingPeriodAssignments,
      selectedAssignmentIds,
      selectedPeriodId,
    )

    const path = `/api/v1/courses/${get().courseId}/assignment_groups`
    const maxAssignments = maxAssignmentCount(params, path)

    // If our assignment_ids param is going to put us over Apache's max URI length,
    // we fall back to requesting all assignments in one query, excluding the
    // assignment_ids param entirely
    if (
      selectedAssignmentIds.length > maxAssignments ||
      otherAssignmentIds.length > maxAssignments
    ) {
      return get().handleAssignmentGroupsResponse({
        promise: get().fetchAssignmentGroups({params, useGraphQL}),
        isSelectedGradingPeriodId: true,
      })
    }

    // If there are no assignments in the selected grading period, request all
    // assignments in a single query
    if (selectedAssignmentIds.length === 0) {
      return get().handleAssignmentGroupsResponse({
        promise: get().fetchAssignmentGroups({params, useGraphQL}),
        isSelectedGradingPeriodId: true,
      })
    }

    // fetch otther grading periods
    const ids2 = otherAssignmentIds.join()
    get().handleAssignmentGroupsResponse({
      promise: get().fetchAssignmentGroups({
        params: {...params, assignment_ids: ids2},
        useGraphQL,
        gradingPeriodIds: otherGradingPeriodIds,
      }),
      isSelectedGradingPeriodId: false,
      gradingPeriodIds: otherGradingPeriodIds,
    })

    // fetch selected grading period
    const ids1 = selectedAssignmentIds.join()
    return get().handleAssignmentGroupsResponse({
      promise: get().fetchAssignmentGroups({
        params: {...params, assignment_ids: ids1},
        useGraphQL,
        gradingPeriodIds: [selectedPeriodId],
      }),
      isSelectedGradingPeriodId: true,
      gradingPeriodIds: [selectedPeriodId],
    })
  },

  fetchAssignmentGroups: ({params, gradingPeriodIds, useGraphQL}) => {
    set({isAssignmentGroupsLoading: true})

    if (useGraphQL) return get().fetchGrapqhlAssignmentGroups({gradingPeriodIds})
    return get().fetchCompositeAssignmentGroups({params})
  },

  fetchCompositeAssignmentGroups: ({params}) => {
    const path = `/api/v1/courses/${get().courseId}/assignment_groups`

    return get().dispatch.getDepaginated<AssignmentGroup[]>(path, params)
  },

  fetchGrapqhlAssignmentGroups: async ({gradingPeriodIds = null}) => {
    const {data: assignmentGroups} = await getAllAssignmentGroups({
      queryParams: {courseId: get().courseId},
    })
    const assignmentGroupIds = assignmentGroups.map(group => group._id)
    const limit = pLimit(GRADEBOOK_GRAPHQL_CONFIG.maxAssignmentRequestCount)

    const assignmentResponses = await Promise.all(
      flatten(
        assignmentGroupIds.map(assignmentGroupId => {
          const gradingPeriodIdsArray = isArray(gradingPeriodIds)
            ? gradingPeriodIds
            : [gradingPeriodIds]

          return gradingPeriodIdsArray.map(gradingPeriodId =>
            limit(() => getAllAssignments({queryParams: {assignmentGroupId, gradingPeriodId}})),
          )
        }),
      ),
    )
    const assignments = flatten(assignmentResponses.map(({data}) => data))

    const assignmentByAssignmentGroupId = groupBy(assignments, 'assignmentGroupId')
    return assignmentGroups.map(group => ({
      ...transformAssignmentGroup(group),
      assignments: (assignmentByAssignmentGroupId?.[group._id] ?? []).map(transformAssignment),
    }))
  },

  handleAssignmentGroupsResponse: async ({
    promise,
    isSelectedGradingPeriodId,
    gradingPeriodIds,
  }) => {
    try {
      const assignmentGroups = await promise
      if (assignmentGroups) {
        const assignments = assignmentGroups.flatMap(group => group.assignments ?? [])
        const assignmentMap = {
          ...get().assignmentMap,
          ...Object.fromEntries(assignments.map(assignment => [assignment.id, assignment])),
        }
        const assignmentList = get().assignmentList.concat(assignments)
        if (isSelectedGradingPeriodId) {
          set({
            recentlyLoadedAssignmentGroups: {
              assignmentGroups,
              gradingPeriodIds,
            },
          })
        }
        set({
          assignmentMap,
          assignmentList,
          assignmentGroups: get().assignmentGroups.concat(assignmentGroups),
        })
      }
      return assignmentGroups
    } catch {
      set({
        flashMessages: get().flashMessages.concat([
          {
            key: 'assignments-groups-loading-error',
            message: I18n.t('There was an error fetching assignment groups data.'),
            variant: 'error',
          },
        ]),
      })
      return undefined
    } finally {
      set({isAssignmentGroupsLoading: false})
    }
  },
})
