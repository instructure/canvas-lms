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

const I18n = useI18nScope('gradebook')

export type StudentsState = {
  studentIds: string[]
  isStudentIdsLoading: boolean
  fetchStudentIds: () => Promise<string[]>
}

export default (set: SetState<GradebookStore>, get: GetState<GradebookStore>): StudentsState => ({
  studentIds: [],

  isStudentIdsLoading: false,

  fetchStudentIds: () => {
    const dispatch = get().dispatch
    const courseId = get().courseId

    set({isStudentIdsLoading: true})

    /*
     * When user ids have been prefetched, the data is only known valid for the
     * first request. Consume it by pulling it out of the prefetch store, which
     * will force all subsequent requests for user ids to call through the
     * network.
     */
    let promise = consumePrefetchedXHR('user_ids')
    if (promise) {
      promise = asJson(promise)
    } else {
      promise = dispatch.getJSON(`/courses/${courseId}/gradebook/user_ids`)
    }

    return promise
      .then((data: {user_ids: string[]}) => {
        set({
          studentIds: data.user_ids,
        })
        return data.user_ids
      })
      .catch(() => {
        set({
          flashMessages: get().flashMessages.concat([
            {
              key: 'student-ids-loading-error',
              message: I18n.t('There was an error fetching student data.'),
              variant: 'error',
            },
          ]),
        })
      })
      .finally(() => {
        set({isStudentIdsLoading: false})
      })
  },
})
