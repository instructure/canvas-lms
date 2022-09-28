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

import {SetState, GetState} from 'zustand'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {GradebookStore} from './index'
import {asJson, consumePrefetchedXHR} from '@instructure/js-utils'
import type {GradingPeriodAssignmentMap} from '../gradebook.d'

const I18n = useI18nScope('gradebook')

export type AssignmentsState = {
  gradingPeriodAssignments: GradingPeriodAssignmentMap
  isGradingPeriodAssignmentsLoading: boolean
  fetchGradingPeriodAssignments: () => Promise<GradingPeriodAssignmentMap>
}

export default (
  set: SetState<GradebookStore>,
  get: GetState<GradebookStore>
): AssignmentsState => ({
  gradingPeriodAssignments: {},

  isGradingPeriodAssignmentsLoading: false,

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

    return promise
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
      })
  },
})
