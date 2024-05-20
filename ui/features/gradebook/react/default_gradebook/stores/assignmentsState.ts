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

import type {SetState, GetState} from 'zustand'
import {useScope as useI18nScope} from '@canvas/i18n'
import {asJson, consumePrefetchedXHR} from '@canvas/util/xhr'
import {maxAssignmentCount, otherGradingPeriodAssignmentIds} from '../Gradebook.utils'
import type {GradebookStore} from './index'
import type {GradingPeriodAssignmentMap} from '../gradebook.d'
import type {AssignmentGroup, Assignment, AssignmentMap, SubmissionType} from '../../../../../api.d'

const I18n = useI18nScope('gradebook')

export type AssignmentsState = {
  gradingPeriodAssignments: GradingPeriodAssignmentMap
  isGradingPeriodAssignmentsLoading: boolean
  isAssignmentGroupsLoading: boolean
  fetchGradingPeriodAssignments: () => Promise<GradingPeriodAssignmentMap>
  loadAssignmentGroupsForGradingPeriods: (
    params: AssignmentLoaderParams,
    selectedPeriodId: string
  ) => Promise<AssignmentGroup[] | undefined>
  loadAssignmentGroups: (
    hideZeroPointQuizzes: boolean,
    currentGradingPeriodId?: string
  ) => Promise<AssignmentGroup[] | undefined>
  fetchAssignmentGroups: (
    params: AssignmentLoaderParams,
    gradingPeriodIds?: string[]
  ) => Promise<AssignmentGroup[] | undefined>
  recentlyLoadedAssignmentGroups: {
    assignmentGroups: AssignmentGroup[]
    gradingPeriodIds?: string[]
  }
  assignmentGroups: AssignmentGroup[]
  assignmentList: Assignment[]
  assignmentMap: AssignmentMap
}

type AssignmentLoaderParams = {
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
  set: SetState<GradebookStore>,
  get: GetState<GradebookStore>
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
    let promise = consumePrefetchedXHR('grading_period_assignments')
    if (promise) {
      promise = asJson(promise)
    } else {
      promise = dispatch.getJSON(`/courses/${courseId}/gradebook/grading_period_assignments`)
    }

    return (
      // @ts-expect-error
      promise
        // @ts-expect-error until consumePrefetchedXHR and dispatch.getJSON support generics
        .then((data: {grading_period_assignments: GradingPeriodAssignmentMap}) => {
          set({
            gradingPeriodAssignments: data.grading_period_assignments,
            isGradingPeriodAssignmentsLoading: false,
          })
          return data.grading_period_assignments
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
          return {}
        })
    )
  },

  loadAssignmentGroups: (
    hideZeroPointQuizzes: boolean = false,
    selectedGradingPeriodId?: string
  ) => {
    const include = [
      'assignment_group_id',
      'assignment_visibility',
      'assignments',
      'grades_published',
      'post_manually',
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

    const normalizeGradingdPeriodId = normalizeGradingPeriodId(selectedGradingPeriodId)
    if (normalizeGradingdPeriodId) {
      return get().loadAssignmentGroupsForGradingPeriods(params, normalizeGradingdPeriodId)
    }

    return get().fetchAssignmentGroups(params)
  },

  loadAssignmentGroupsForGradingPeriods(params: AssignmentLoaderParams, selectedPeriodId: string) {
    const selectedAssignmentIds: string[] = get().gradingPeriodAssignments[selectedPeriodId] || []

    const {otherAssignmentIds, otherGradingPeriodIds} = otherGradingPeriodAssignmentIds(
      get().gradingPeriodAssignments,
      selectedAssignmentIds,
      selectedPeriodId
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
      return get().fetchAssignmentGroups(params)
    }

    // If there are no assignments in the selected grading period, request all
    // assignments in a single query
    if (selectedAssignmentIds.length === 0) {
      return get().fetchAssignmentGroups(params)
    }

    const ids1 = selectedAssignmentIds.join()
    const gotGroups = get().fetchAssignmentGroups({...params, assignment_ids: ids1}, [
      selectedPeriodId,
    ])

    const ids2 = otherAssignmentIds.join()
    get().fetchAssignmentGroups({...params, assignment_ids: ids2}, otherGradingPeriodIds)

    return gotGroups
  },

  fetchAssignmentGroups: (
    params: AssignmentLoaderParams,
    gradingPeriodIds?: string[]
  ): Promise<undefined | AssignmentGroup[]> => {
    set({isAssignmentGroupsLoading: true})

    const path = `/api/v1/courses/${get().courseId}/assignment_groups`

    return get()
      .dispatch.getDepaginated<AssignmentGroup[]>(path, params)
      .then((assignmentGroups: undefined | AssignmentGroup[]) => {
        if (assignmentGroups) {
          const assignments = assignmentGroups.flatMap(group => group.assignments)
          const assignmentMap = {
            ...get().assignmentMap,
            ...Object.fromEntries(assignments.map(assignment => [assignment.id, assignment])),
          }
          const assignmentList = get().assignmentList.concat(assignments)
          set({
            recentlyLoadedAssignmentGroups: {
              assignmentGroups,
              gradingPeriodIds,
            },
            assignmentMap,
            assignmentList,
            assignmentGroups: get().assignmentGroups.concat(assignmentGroups),
          })
        }
        return assignmentGroups
      })
      .catch(() => {
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
      })
      .finally(() => {
        set({isAssignmentGroupsLoading: false})
      })
  },
})
