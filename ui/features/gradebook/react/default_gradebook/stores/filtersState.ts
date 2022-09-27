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
import uuid from 'uuid'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {Filter, FilterPreset, PartialFilterPreset} from '../gradebook.d'
import {
  compareFilterSetByUpdatedDate,
  deserializeFilter,
  doFiltersMatch,
  isFilterNotEmpty,
} from '../Gradebook.utils'
import GradebookApi from '../apis/GradebookApi'
import type {GradebookStore} from './index'

const I18n = useI18nScope('gradebook')

export type FiltersState = {
  appliedFilters: Filter[]
  filterPresets: FilterPreset[]
  stagedFilters: Filter[]
  isFiltersLoading: boolean

  addFilters: (filters: Filter[]) => void
  applyFilters: (filters: Filter[]) => void
  toggleFilter: (filter: Filter) => void
  initializeStagedFilter: (InitialColumnFilterSettings, InitialRowFilterSettings) => void
  fetchFilters: () => Promise<void>
  saveStagedFilter: (filterPreset: PartialFilterPreset) => Promise<void>
  updateStagedFilterPreset: (filters: Filter[]) => void
  updateFilterPreset: (filterPreset: FilterPreset) => Promise<void>
  deleteFilterPreset: (filterPreset: FilterPreset) => Promise<void>
}

export type InitialColumnFilterSettings = {
  assignment_group_id: null | string
  context_module_id: null | string
  grading_period_id: null | string
  submissions: null | 'has-submissions' | 'has-ungraded-submissions'
  start_date: null | string
  end_date: null | string
}

export type InitialRowFilterSettings = {
  section_id: null | string
  student_group_id: null | string
}

export default (set: SetState<GradebookStore>, get: GetState<GradebookStore>): FiltersState => ({
  appliedFilters: [],

  filterPresets: [],

  stagedFilters: [],

  isFiltersLoading: false,

  applyFilters: (appliedFilters: Filter[]) => {
    set({appliedFilters})
  },

  addFilters: (filters: Filter[]) => {
    const types = filters.map(c => c.type)
    const newFilters = [...get().appliedFilters.filter(c => !types.includes(c.type))].concat(
      filters
    )
    get().applyFilters(newFilters)
  },

  toggleFilter: (filter: Filter) => {
    const existingFilter = get().appliedFilters.find(
      f => f.type === filter.type && f.value === filter.value
    )
    set({
      appliedFilters: [...get().appliedFilters.filter(f => f.type !== filter.type)].concat(
        existingFilter ? [] : [filter]
      ),
    })
  },

  initializeStagedFilter: (
    initialRowFilterSettings: InitialRowFilterSettings,
    initialColumnFilterSettings: InitialColumnFilterSettings
  ) => {
    const filters: Filter[] = []

    if (typeof initialRowFilterSettings.section_id === 'string') {
      filters.push({
        id: uuid.v4(),
        value: initialRowFilterSettings.section_id,
        type: 'section',
        created_at: new Date().toISOString(),
      })
    }

    if (typeof initialRowFilterSettings.student_group_id === 'string') {
      filters.push({
        id: uuid.v4(),
        value: initialRowFilterSettings.student_group_id,
        type: 'student-group',
        created_at: new Date().toISOString(),
      })
    }

    if (
      typeof initialColumnFilterSettings.assignment_group_id === 'string' &&
      initialColumnFilterSettings.assignment_group_id !== '0'
    ) {
      filters.push({
        id: uuid.v4(),
        value: initialColumnFilterSettings.assignment_group_id,
        type: 'assignment-group',
        created_at: new Date().toISOString(),
      })
    }

    if (
      ['has-ungraded-submissions', 'has-submissions'].includes(
        initialColumnFilterSettings.submissions || ''
      )
    ) {
      filters.push({
        id: uuid.v4(),
        value: initialColumnFilterSettings.submissions || undefined,
        type: 'submissions',
        created_at: new Date().toISOString(),
      })
    }

    if (
      typeof initialColumnFilterSettings.context_module_id === 'string' &&
      initialColumnFilterSettings.context_module_id !== '0'
    ) {
      filters.push({
        id: uuid.v4(),
        value: initialColumnFilterSettings.context_module_id,
        type: 'module',
        created_at: new Date().toISOString(),
      })
    }

    if (initialColumnFilterSettings.start_date && initialColumnFilterSettings.start_date !== '0') {
      filters.push({
        id: uuid.v4(),
        value: initialColumnFilterSettings.start_date,
        type: 'start-date',
        created_at: new Date().toISOString(),
      })
    }

    if (initialColumnFilterSettings.end_date && initialColumnFilterSettings.end_date !== '0') {
      filters.push({
        id: uuid.v4(),
        value: initialColumnFilterSettings.end_date,
        type: 'end-date',
        created_at: new Date().toISOString(),
      })
    }

    if (
      typeof initialColumnFilterSettings.grading_period_id === 'string' &&
      initialColumnFilterSettings.grading_period_id !== '0'
    ) {
      filters.push({
        id: uuid.v4(),
        value: initialColumnFilterSettings.grading_period_id,
        type: 'grading-period',
        created_at: new Date().toISOString(),
      })
    }

    const savedFilterAlreadyMatches = get().filterPresets.some(filterPreset =>
      doFiltersMatch(filterPreset.filters, filters)
    )

    set({
      appliedFilters: filters,
      stagedFilters: !savedFilterAlreadyMatches ? filters : [],
    })
  },

  fetchFilters: async () => {
    set({isFiltersLoading: true})
    const path = `/api/v1/courses/${get().courseId}/gradebook_filters`
    return doFetchApi({path})
      .then(response => {
        set({
          filterPresets: response.json.map(deserializeFilter).sort(compareFilterSetByUpdatedDate),
          isFiltersLoading: false,
        })
      })
      .catch(() => {
        set({
          filterPresets: [],
          isFiltersLoading: false,
          flashMessages: get().flashMessages.concat([
            {
              key: 'filter-presets-loading-error',
              message: I18n.t('There was an error fetching gradebook filters.'),
              variant: 'error',
            },
          ]),
        })
      })
  },

  updateStagedFilterPreset: (newStagedFilters: Filter[]) => {
    const appliedFilters = get().appliedFilters.filter(isFilterNotEmpty)
    const stagedFilters = get().stagedFilters
    const isFilterApplied = doFiltersMatch(stagedFilters, appliedFilters)

    set({
      stagedFilters: newStagedFilters,
      appliedFilters: isFilterApplied
        ? newStagedFilters.filter(isFilterNotEmpty)
        : get().appliedFilters,
    })
  },

  saveStagedFilter: async (filterPreset: PartialFilterPreset) => {
    const filters = filterPreset.filters.filter(isFilterNotEmpty)
    if (!filters.length) return
    const originalFilters = get().filterPresets
    const stagedFilter: FilterPreset = {
      id: uuid.v4() as string,
      name: filterPreset.name,
      filters,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    }

    // optimistic update
    set({
      filterPresets: get().filterPresets.concat([stagedFilter]).sort(compareFilterSetByUpdatedDate),
      stagedFilters: [],
    })

    return GradebookApi.createGradebookFilterPreset(get().courseId, stagedFilter)
      .then(response => {
        const newFilter = deserializeFilter(response.json)
        set({
          stagedFilters: [],
          filterPresets: originalFilters.concat([newFilter]).sort(compareFilterSetByUpdatedDate),
        })
      })
      .catch(() => {
        set({
          stagedFilters: filterPreset.filters,
          flashMessages: get().flashMessages.concat([
            {
              key: `filter-presets-create-error-${Date.now()}`,
              message: I18n.t('There was an error creating a new filter.'),
              variant: 'error',
            },
          ]),
        })
      })
  },

  updateFilterPreset: async (filterPreset: FilterPreset) => {
    const originalFilter = get().filterPresets.find(f => f.id === filterPreset.id)
    const otherFilters = get().filterPresets.filter(f => f.id !== filterPreset.id)
    const appliedFilters = get().appliedFilters

    const isFilterApplied = doFiltersMatch(originalFilter?.filters || [], appliedFilters)

    // optimistic update
    set({
      filterPresets: otherFilters.concat([filterPreset]).sort(compareFilterSetByUpdatedDate),
      appliedFilters: isFilterApplied ? filterPreset.filters : appliedFilters,
    })

    try {
      const response = await GradebookApi.updateGradebookFilterPreset(get().courseId, filterPreset)
      const updatedFilter = deserializeFilter(response.json)
      set({
        filterPresets: get()
          .filterPresets.filter(f => f.id !== filterPreset.id)
          .concat([updatedFilter])
          .sort(compareFilterSetByUpdatedDate),
        appliedFilters: isFilterApplied ? updatedFilter.filters : appliedFilters,
      })
    } catch (err) {
      // rewind
      if (originalFilter) {
        set({
          filterPresets: get()
            .filterPresets.filter(f => f.id !== filterPreset.id)
            .concat([originalFilter])
            .sort(compareFilterSetByUpdatedDate),
          appliedFilters,
        })
      }

      set({
        flashMessages: get().flashMessages.concat([
          {
            key: `filter-presets-create-error-${Date.now()}`,
            message: I18n.t('There was an error updating a filter.'),
            variant: 'error',
          },
        ]),
      })
    }
  },

  deleteFilterPreset: (filterPreset: FilterPreset) => {
    const appliedFilters = get().appliedFilters
    const isFilterApplied = doFiltersMatch(filterPreset.filters, get().appliedFilters)

    // Optimistic update
    set({
      filterPresets: get().filterPresets.filter(f => f.id !== filterPreset.id),
      appliedFilters: isFilterApplied ? [] : appliedFilters,
    })

    return GradebookApi.deleteGradebookFilterPreset(get().courseId, filterPreset.id).catch(() => {
      // rewind
      const isAbsent = get().filterPresets.some(f => f.id === filterPreset.id)
      if (!isAbsent) {
        set({
          filterPresets: get()
            .filterPresets.concat([filterPreset])
            .sort(compareFilterSetByUpdatedDate),
        })
      }

      set({
        flashMessages: get().flashMessages.concat([
          {
            key: `filter-presets-delete-error-${filterPreset.id}-${Date.now()}`,
            message: I18n.t('There was an error deleting "%{name}".', {name: filterPreset.name}),
            variant: 'error',
          },
        ]),
        appliedFilters,
      })
    })
  },
})
