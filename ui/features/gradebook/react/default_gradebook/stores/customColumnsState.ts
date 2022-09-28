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

import {GetState, SetState} from 'zustand'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {CustomColumn} from '../gradebook.d'
import type {GradebookStore} from './index'

const I18n = useI18nScope('gradebook')

export type CustomColumnsState = {
  customColumns: CustomColumn[]
  isCustomColumnsLoading: boolean
  fetchCustomColumns: () => Promise<any>
}

export default (
  set: SetState<GradebookStore>,
  get: GetState<GradebookStore>
): CustomColumnsState => ({
  customColumns: [],

  isCustomColumnsLoading: false,

  fetchCustomColumns: () => {
    const dispatch = get().dispatch
    const courseId = get().courseId
    set({isCustomColumnsLoading: true})
    const url = `/api/v1/courses/${courseId}/custom_gradebook_columns`
    const params = {
      include_hidden: true,
      per_page: get().performanceControls.customColumnsPerPage
    }
    return dispatch
      .getDepaginated(url, params)
      .then((customColumns: CustomColumn[]) => {
        set({customColumns, isCustomColumnsLoading: false})
      })
      .catch(() => {
        set({
          customColumns: [],
          isCustomColumnsLoading: false,
          flashMessages: get().flashMessages.concat([
            {
              key: 'custom-columns-loading-error',
              message: I18n.t('There was an error fetching custom columns.'),
              variant: 'error'
            }
          ])
        })
      })
  }
})
