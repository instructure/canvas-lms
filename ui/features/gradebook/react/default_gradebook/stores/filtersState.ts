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
import doFetchApi from '@canvas/do-fetch-api-effect'
// @ts-ignore
import I18n from 'i18n!gradebook'
import type {PartialFilter, AppliedFilter, Filter} from '../gradebook.d'
import {deserializeFilter, serializeFilter, compareFilterByDate} from '../Gradebook.utils'
import type {GradebookStore} from './index'

export type FiltersState = {
  filters: Filter[]
  stagedFilter: null | PartialFilter
  isFiltersLoading: boolean

  appliedFilters: () => AppliedFilter[]
  fetchFilters: () => Promise<void>
  saveStagedFilter: () => Promise<void>
  updateFilter: (filter: Filter) => Promise<void>
  deleteFilter: (filter: Filter) => Promise<any>
}

export default (set: SetState<GradebookStore>, get: GetState<GradebookStore>): FiltersState => ({
  filters: [],

  stagedFilter: null,

  isFiltersLoading: false,

  appliedFilters: () => {
    const allFilters = get().stagedFilter ? [...get().filters, get().stagedFilter!] : get().filters
    return allFilters.filter(filter => filter.is_applied) as AppliedFilter[]
  },

  fetchFilters: async () => {
    set({isFiltersLoading: true})
    const path = `/api/v1/courses/${get().courseId}/gradebook_filters`
    return doFetchApi({path})
      .then(response => {
        set({
          filters: response.json.map(deserializeFilter),
          isFiltersLoading: false
        })
      })
      .catch(() => {
        set({
          filters: [],
          isFiltersLoading: false,
          flashMessages: get().flashMessages.concat([
            {
              key: 'filters-loading-error',
              message: I18n.t('There was an error fetching gradebook filters.'),
              variant: 'error'
            }
          ])
        })
      })
  },

  saveStagedFilter: () => {
    const stagedFilter = get().stagedFilter
    if (!stagedFilter) throw new Error('staged filter is null')

    const {name, payload} = serializeFilter(stagedFilter)

    return doFetchApi({
      path: `/api/v1/courses/${get().courseId}/gradebook_filters`,
      method: 'POST',
      body: {gradebook_filter: {name, payload}}
    })
      .then(response => {
        const newFilter = deserializeFilter(response.json)
        set({
          stagedFilter: null,
          filters: get().filters.concat([newFilter]).sort(compareFilterByDate)
        })
      })
      .catch(() => {
        set({
          flashMessages: get().flashMessages.concat([
            {
              key: `filters-create-error-${Date.now()}`,
              message: I18n.t('There was an error creating a new filter.'),
              variant: 'error'
            }
          ])
        })
      })
  },

  updateFilter: (filter: Filter) => {
    const originalFilter = get().filters.find(f => f.id !== filter.id)

    // optimistic update
    set({
      filters: get()
        .filters.filter(f => f.id !== filter.id)
        .concat([filter])
        .sort(compareFilterByDate)
    })

    const {name, payload} = serializeFilter(filter)

    return doFetchApi({
      path: `/api/v1/courses/${get().courseId}/gradebook_filters/${filter.id}`,
      method: 'PUT',
      body: {gradebook_filter: {name, payload}}
    })
      .then(response => {
        const updatedFilter = deserializeFilter(response.json)
        set({
          filters: get()
            .filters.filter(f => f.id !== filter.id)
            .concat([updatedFilter])
            .sort(compareFilterByDate)
        })
      })
      .catch(() => {
        // rewind
        if (originalFilter) {
          set({
            filters: get()
              .filters.filter(f => f.id !== filter.id)
              .concat([originalFilter])
              .sort(compareFilterByDate)
          })
        }

        set({
          flashMessages: get().flashMessages.concat([
            {
              key: `filters-create-error-${Date.now()}`,
              message: I18n.t('There was an error updating a filter.'),
              variant: 'error'
            }
          ])
        })
      })
  },

  deleteFilter: (filter: Filter) => {
    // Optimistic update
    set({filters: get().filters.filter(f => f.id !== filter.id)})

    return doFetchApi({
      path: `/api/v1/courses/${get().courseId}/gradebook_filters/${filter.id}`,
      method: 'DELETE'
    }).catch(() => {
      // rewind
      const isAbsent = get().filters.some(f => f.id === filter.id)
      if (!isAbsent) {
        set({filters: get().filters.concat([filter]).sort(compareFilterByDate)})
      }

      set({
        flashMessages: get().flashMessages.concat([
          {
            key: `filters-delete-error-${filter.id}-${Date.now()}`,
            message: I18n.t('There was an error deleting "%{name}".', {name: filter.name}),
            variant: 'error'
          }
        ])
      })
    })
  }
})
