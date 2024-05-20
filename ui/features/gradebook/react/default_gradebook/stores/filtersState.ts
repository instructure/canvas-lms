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
import uuid from 'uuid'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {
  Filter,
  FilterPreset,
  GradebookFilterApiResponse,
  PartialFilterPreset,
  SubmissionFilterValue,
} from '../gradebook.d'
import {
  compareFilterSetByUpdatedDate,
  deserializeFilter,
  doFiltersMatch,
  getCustomStatusIdStrings,
  isFilterNotEmpty,
} from '../Gradebook.utils'
import GradebookApi from '../apis/GradebookApi'
import type {GradebookStore} from './index'
import type {GradeStatus} from '@canvas/grading/accountGradingStatus'

const I18n = useI18nScope('gradebook')

export type FiltersState = {
  appliedFilters: Filter[]
  filterPresets: FilterPreset[]
  stagedFilterPresetName: string
  stagedFilters: Filter[]
  isFiltersLoading: boolean

  addFilters: (filters: Filter[]) => void
  applyFilters: (filters: Filter[]) => void
  toggleFilter: (filter: Filter) => void
  toggleFilterMultiSelect: (filter: Filter) => void
  initializeAppliedFilters: (
    initialRowFilterSettings: InitialRowFilterSettings,
    initialColumnFilterSettings: InitialColumnFilterSettings,
    customGradeStatuses: GradeStatus[],
    multiselectGradebookFiltersEnabled: boolean
  ) => void
  initializeStagedFilters: () => void
  fetchFilters: () => Promise<void>
  saveStagedFilter: (filterPreset: PartialFilterPreset) => Promise<boolean>
  updateFilterPreset: (filterPreset: FilterPreset) => Promise<boolean>
  deleteFilterPreset: (filterPreset: FilterPreset) => Promise<void>
  validateFilterPreset: (
    name: string,
    filters: Filter[],
    otherFilterPresets: FilterPreset[]
  ) => boolean
}

export type InitialColumnFilterSettings = {
  assignment_group_id: null | string
  assignment_group_ids?: string[]
  context_module_id: null | string
  context_module_ids?: string[]
  grading_period_id: null | string
  submissions: null | SubmissionFilterValue
  submission_filters?: SubmissionFilterValue[]
  start_date: null | string
  end_date: null | string
}

export type InitialRowFilterSettings = {
  section_id: null | string
  section_ids?: string[]
  student_group_id: null | string
  student_group_ids?: null | string[]
}

export default (set: SetState<GradebookStore>, get: GetState<GradebookStore>): FiltersState => ({
  appliedFilters: [],

  filterPresets: [],

  stagedFilterPresetName: '',

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

  toggleFilterMultiSelect: (filter: Filter) => {
    const existingFilter = get().appliedFilters.find(
      f => f.type === filter.type && f.value === filter.value
    )

    let appliedFilters = [...get().appliedFilters]

    const excludedMultiselectFilters = ['grading-period']
    appliedFilters = excludedMultiselectFilters.includes(filter.type ?? '')
      ? appliedFilters.filter(f => f.type !== filter.type)
      : appliedFilters.filter(f => !(f.type === filter.type && f.value === filter.value))

    set({
      appliedFilters: appliedFilters.concat(existingFilter ? [] : [filter]),
    })
  },

  initializeAppliedFilters: (
    initialRowFilterSettings: InitialRowFilterSettings,
    initialColumnFilterSettings: InitialColumnFilterSettings,
    customStatuses: GradeStatus[],
    multiselectGradebookFiltersEnabled: boolean
  ) => {
    const appliedFilters: Filter[] = []

    if (multiselectGradebookFiltersEnabled) {
      initialColumnFilterSettings.context_module_ids?.forEach(value => {
        appliedFilters.push({
          id: uuid.v4(),
          value,
          type: 'module',
          created_at: new Date().toISOString(),
        })
      })
      initialColumnFilterSettings.assignment_group_ids?.forEach(value => {
        appliedFilters.push({
          id: uuid.v4(),
          value,
          type: 'assignment-group',
          created_at: new Date().toISOString(),
        })
      })
      initialColumnFilterSettings.submission_filters?.forEach(value => {
        appliedFilters.push({
          id: uuid.v4(),
          value,
          type: 'submissions',
          created_at: new Date().toISOString(),
        })
      })
      initialRowFilterSettings.section_ids?.forEach(value => {
        appliedFilters.push({
          id: uuid.v4(),
          value,
          type: 'section',
          created_at: new Date().toISOString(),
        })
      })
      initialRowFilterSettings.student_group_ids?.forEach(value => {
        appliedFilters.push({
          id: uuid.v4(),
          value,
          type: 'student-group',
          created_at: new Date().toISOString(),
        })
      })
      // NOTE: all "saved" filters will be wiped out when multi select
      // filters are enabled, could look into preserving this when
      // the feature gets turned on if it is an issue
    } else {
      if (typeof initialRowFilterSettings.section_id === 'string') {
        appliedFilters.push({
          id: uuid.v4(),
          value: initialRowFilterSettings.section_id,
          type: 'section',
          created_at: new Date().toISOString(),
        })
      }
      if (typeof initialRowFilterSettings.student_group_id === 'string') {
        appliedFilters.push({
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
        appliedFilters.push({
          id: uuid.v4(),
          value: initialColumnFilterSettings.assignment_group_id,
          type: 'assignment-group',
          created_at: new Date().toISOString(),
        })
      }
      const customStatusIds = getCustomStatusIdStrings(customStatuses)
      if (
        [
          'has-ungraded-submissions',
          'has-submissions',
          'has-no-submissions',
          'has-unposted-grades',
          'late',
          'missing',
          'resubmitted',
          'dropped',
          'excused',
          'extended',
          ...customStatusIds,
        ].includes(initialColumnFilterSettings.submissions || '')
      ) {
        appliedFilters.push({
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
        appliedFilters.push({
          id: uuid.v4(),
          value: initialColumnFilterSettings.context_module_id,
          type: 'module',
          created_at: new Date().toISOString(),
        })
      }

      if (
        initialColumnFilterSettings.start_date &&
        initialColumnFilterSettings.start_date !== '0'
      ) {
        appliedFilters.push({
          id: uuid.v4(),
          value: initialColumnFilterSettings.start_date,
          type: 'start-date',
          created_at: new Date().toISOString(),
        })
      }

      if (initialColumnFilterSettings.end_date && initialColumnFilterSettings.end_date !== '0') {
        appliedFilters.push({
          id: uuid.v4(),
          value: initialColumnFilterSettings.end_date,
          type: 'end-date',
          created_at: new Date().toISOString(),
        })
      }

      if (typeof initialColumnFilterSettings.grading_period_id === 'string') {
        appliedFilters.push({
          id: uuid.v4(),
          value: initialColumnFilterSettings.grading_period_id,
          type: 'grading-period',
          created_at: new Date().toISOString(),
        })
      }
    }

    set({appliedFilters})
  },

  initializeStagedFilters: () => {
    const appliedFilters = get().appliedFilters

    const savedFiltersAlreadyMatch = get().filterPresets.some(filterPreset =>
      doFiltersMatch(filterPreset.filters, appliedFilters)
    )

    set({
      stagedFilters: savedFiltersAlreadyMatch ? [] : appliedFilters,
    })
  },

  fetchFilters: async () => {
    set({isFiltersLoading: true})
    const path = `/api/v1/courses/${get().courseId}/gradebook_filters`
    return doFetchApi({path})
      .then((response: {json: GradebookFilterApiResponse[]}) => {
        set({
          filterPresets: response.json.map(deserializeFilter).sort(compareFilterSetByUpdatedDate),
          isFiltersLoading: false,
        })
        get().initializeStagedFilters()
      })
      .catch(() => {
        set({
          filterPresets: [],
          isFiltersLoading: false,
          flashMessages: get().flashMessages.concat([
            {
              key: `filter-presets-loading-error-${Date.now()}`,
              message: I18n.t('There was an error fetching gradebook filters.'),
              variant: 'error',
            },
          ]),
        })
      })
  },

  validateFilterPreset: (
    name: string,
    filters: Filter[],
    otherFilterPresets: FilterPreset[]
  ): boolean => {
    const filtersNotEmpty = filters.filter(isFilterNotEmpty)

    if (!filtersNotEmpty.length) {
      set({
        flashMessages: get().flashMessages.concat([
          {
            key: `filter-presets-create-error-no-filters-${Date.now()}`,
            message: I18n.t('Please select at least one filter.'),
            variant: 'error',
          },
        ]),
      })
      return false
    }

    // check for duplicate filter preset name
    if (otherFilterPresets.some(fp => fp.name === name)) {
      set({
        flashMessages: get().flashMessages.concat([
          {
            key: `filter-presets-create-error-duplicate-name-${Date.now()}`,
            message: I18n.t('A filter with that name already exists.'),
            variant: 'error',
          },
        ]),
      })
      return false
    }

    // check for duplicate filter preset using doFiltersMatch
    if (otherFilterPresets.some(fp => doFiltersMatch(fp.filters, filtersNotEmpty))) {
      set({
        flashMessages: get().flashMessages.concat([
          {
            key: `filter-presets-create-error-duplicate-filters-${Date.now()}`,
            message: I18n.t('A filter preset with those conditions already exists.'),
            variant: 'error',
          },
        ]),
      })
      return false
    }

    return true
  },

  saveStagedFilter: async (filterPreset: PartialFilterPreset) => {
    const filters = filterPreset.filters.filter(isFilterNotEmpty)

    if (!get().validateFilterPreset(filterPreset.name, filters, get().filterPresets)) {
      return false
    }

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
      stagedFilterPresetName: '',
      stagedFilters: [],
    })

    return GradebookApi.createGradebookFilterPreset(get().courseId, stagedFilter)
      .then((response: {json: GradebookFilterApiResponse}) => {
        const newFilter = deserializeFilter(response.json)
        set({
          filterPresets: originalFilters.concat([newFilter]).sort(compareFilterSetByUpdatedDate),
        })
        return true
      })
      .catch(() => {
        set({
          stagedFilterPresetName: filterPreset.name,
          stagedFilters: filterPreset.filters,
          flashMessages: get().flashMessages.concat([
            {
              key: `filter-presets-create-error-${Date.now()}`,
              message: I18n.t('There was an error creating a new filter.'),
              variant: 'error',
            },
          ]),
        })
        return false
      })
  },

  updateFilterPreset: async (filterPreset: FilterPreset) => {
    const otherFilterPresets = get().filterPresets.filter(f => f.id !== filterPreset.id)

    if (!get().validateFilterPreset(filterPreset.name, filterPreset.filters, otherFilterPresets)) {
      return false
    }

    const originalFilterPreset = get().filterPresets.find(f => f.id === filterPreset.id)
    const appliedFilters = get().appliedFilters

    const isFilterApplied = doFiltersMatch(originalFilterPreset?.filters || [], appliedFilters)

    // optimistic update
    set({
      filterPresets: otherFilterPresets.concat([filterPreset]).sort(compareFilterSetByUpdatedDate),
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
      return true
    } catch (err) {
      // rewind
      if (originalFilterPreset) {
        set({
          filterPresets: get()
            .filterPresets.filter(f => f.id !== filterPreset.id)
            .concat([originalFilterPreset])
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

      return false
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
