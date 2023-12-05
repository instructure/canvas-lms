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

import $ from 'jquery'
import axios from '@canvas/axios'
import type {GetState, SetState} from 'zustand'
import {useScope as useI18nScope} from '@canvas/i18n'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import type {CustomColumn, CustomColumnData, ColumnOrderSettings} from '../gradebook.d'
import type {GradebookStore} from './index'

const I18n = useI18nScope('gradebook')

export type CustomColumnsState = {
  reorderCustomColumnsUrl: string
  customColumns: CustomColumn[]
  isCustomColumnsLoading: boolean
  isCustomColumnsLoaded: boolean
  fetchCustomColumns: () => Promise<void>
  reorderCustomColumns: (columnIds: string[]) => Promise<void>
  loadCustomColumnsData: (columnIds: string[]) => Promise<CustomColumnData[][]>
  loadDataForCustomColumn: (columnId: string) => Promise<CustomColumnData[]>
  recentlyLoadedCustomColumnData: null | {
    customColumnId: string
    columnData: CustomColumnData[]
  }
  updateColumnOrder: (courseId: string, columnOrder: ColumnOrderSettings) => Promise<void>
}

export default (
  set: SetState<GradebookStore>,
  get: GetState<GradebookStore>
): CustomColumnsState => ({
  reorderCustomColumnsUrl: '',

  customColumns: [],

  isCustomColumnsLoading: false,

  isCustomColumnsLoaded: false,

  recentlyLoadedCustomColumnData: null,

  fetchCustomColumns: () => {
    const dispatch = get().dispatch
    const courseId = get().courseId
    set({isCustomColumnsLoading: true})
    const url = `/api/v1/courses/${courseId}/custom_gradebook_columns`
    const params = {
      include_hidden: true,
      per_page: get().performanceControls.customColumnsPerPage,
    }
    return dispatch
      .getDepaginated<CustomColumn[]>(url, params)
      .then(customColumns => {
        set({customColumns, isCustomColumnsLoading: false, isCustomColumnsLoaded: true})
        get()
          .loadCustomColumnsData(customColumns.map(column => column.id))
          .catch(() => {
            FlashAlert.showFlashError(
              I18n.t('There was an error fetching custom column data for Gradebook')
            )
          })
      })
      .catch(() => {
        set({
          customColumns: [],
          isCustomColumnsLoading: false,
          flashMessages: get().flashMessages.concat([
            {
              key: 'custom-columns-loading-error',
              message: I18n.t('There was an error fetching custom columns.'),
              variant: 'error',
            },
          ]),
        })
      })
  },

  reorderCustomColumns: (columnIds: string[]) =>
    $.ajaxJSON(get().reorderCustomColumnsUrl, 'POST', {
      order: columnIds,
    }),

  loadCustomColumnsData: (columnIds: string[] = []): Promise<CustomColumnData[][]> => {
    const customColumnsDataLoadingPromises = columnIds.map(columnId =>
      get().loadDataForCustomColumn(columnId)
    )

    return Promise.all(customColumnsDataLoadingPromises)
  },

  loadDataForCustomColumn: (columnId: string) => {
    const courseId = get().courseId
    const performanceControls = get().performanceControls
    const dispatch = get().dispatch

    const url = `/api/v1/courses/${courseId}/custom_gradebook_columns/${columnId}/data`
    const params = {
      include_hidden: true,
      per_page: performanceControls.customColumnDataPerPage,
    }

    const perPageCallback = (customColumnData: CustomColumnData[]) => {
      set({
        recentlyLoadedCustomColumnData: {
          customColumnId: columnId,
          columnData: customColumnData,
        },
      })
      return customColumnData
    }

    return dispatch.getDepaginated<CustomColumnData[]>(url, params, perPageCallback)
  },

  updateColumnOrder: (courseId: string, columnOrder: ColumnOrderSettings) => {
    const url = `/courses/${courseId}/gradebook/save_gradebook_column_order`
    return axios.post(url, {column_order: columnOrder})
  },
})
