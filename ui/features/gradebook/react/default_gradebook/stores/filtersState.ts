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
// @ts-ignore
import {useScope as useI18nScope} from '@canvas/i18n'
import type {PartialFilter, AppliedFilter, FilterCondition, Filter} from '../gradebook.d'
import {
  deserializeFilter,
  compareFilterByDate,
  findAllAppliedFilterValuesOfType
} from '../Gradebook.utils'
import GradebookApi from '../apis/GradebookApi'
import type {GradebookStore} from './index'

const I18n = useI18nScope('gradebook')

export type FiltersState = {
  filters: Filter[]
  stagedFilter: null | PartialFilter
  isFiltersLoading: boolean

  appliedFilters: () => AppliedFilter[]
  initializeStagedFilter: (InitialColumnFilterSettings, InitialRowFilterSettings) => void
  fetchFilters: () => Promise<void>
  saveStagedFilter: () => Promise<void>
  updateFilter: (filter: Filter) => Promise<void>
  deleteFilter: (filter: Filter) => Promise<any>
}

type InitialColumnFilterSettings = {
  assignment_group_id: null | string
  context_module_id: null | string
  grading_period_id: null | string
}

type InitialRowFilterSettings = {
  section_id: null | string
  student_group_id: null | string
}

export default (set: SetState<GradebookStore>, get: GetState<GradebookStore>): FiltersState => ({
  filters: [],

  stagedFilter: null,

  isFiltersLoading: false,

  appliedFilters: () => {
    const allFilters = get().stagedFilter ? [...get().filters, get().stagedFilter!] : get().filters
    return allFilters.filter(filter => filter.is_applied) as AppliedFilter[]
  },

  initializeStagedFilter: (
    initialRowFilterSettings: InitialRowFilterSettings,
    initialColumnFilterSettings: InitialColumnFilterSettings
  ) => {
    const conditions: FilterCondition[] = []

    // Is section filter not represented?
    if (
      initialRowFilterSettings.section_id &&
      !findAllAppliedFilterValuesOfType('section', get().filters).includes(
        initialRowFilterSettings.section_id
      )
    ) {
      conditions.push({
        id: uuid.v4(),
        value: initialRowFilterSettings.section_id,
        type: 'section',
        created_at: new Date().toISOString()
      })
    }

    // Is student group filter not represented?
    if (
      initialRowFilterSettings.student_group_id &&
      !findAllAppliedFilterValuesOfType('student-group', get().filters).includes(
        initialRowFilterSettings.student_group_id
      )
    ) {
      conditions.push({
        id: uuid.v4(),
        value: initialRowFilterSettings.student_group_id,
        type: 'student-group',
        created_at: new Date().toISOString()
      })
    }

    // Is assignment group filter not represented?
    if (
      initialColumnFilterSettings.assignment_group_id &&
      initialColumnFilterSettings.assignment_group_id !== '0' &&
      !findAllAppliedFilterValuesOfType('assignment-group', get().filters).includes(
        initialColumnFilterSettings.assignment_group_id
      )
    ) {
      conditions.push({
        id: uuid.v4(),
        value: initialColumnFilterSettings.assignment_group_id,
        type: 'assignment-group',
        created_at: new Date().toISOString()
      })
    }

    // Is module filter not represented?
    if (
      initialColumnFilterSettings.context_module_id &&
      initialColumnFilterSettings.context_module_id !== '0' &&
      !findAllAppliedFilterValuesOfType('module', get().filters).includes(
        initialColumnFilterSettings.context_module_id
      )
    ) {
      conditions.push({
        id: uuid.v4(),
        value: initialColumnFilterSettings.context_module_id,
        type: 'module',
        created_at: new Date().toISOString()
      })
    }

    // Is grading period filter not represented?
    if (
      initialColumnFilterSettings.grading_period_id &&
      !findAllAppliedFilterValuesOfType('grading-period', get().filters).includes(
        initialColumnFilterSettings.grading_period_id
      )
    ) {
      conditions.push({
        id: uuid.v4(),
        value: initialColumnFilterSettings.grading_period_id,
        type: 'grading-period',
        created_at: new Date().toISOString()
      })
    }

    if (conditions.length > 0) {
      const stagedFilter: PartialFilter = {
        name: '',
        conditions,
        is_applied: true,
        created_at: new Date().toISOString()
      }
      set({stagedFilter})
    }
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

  saveStagedFilter: async () => {
    const stagedFilter = get().stagedFilter
    if (!stagedFilter) throw new Error('staged filter is null')

    const otherFilters = get().filters.filter(f => f.id !== stagedFilter.id)
    const previouslyAppliedFilters = otherFilters.filter(f => f.is_applied)

    if (stagedFilter.is_applied && previouslyAppliedFilters.length > 0) {
      try {
        await Promise.all(
          previouslyAppliedFilters.map(applidFilter =>
            GradebookApi.updateGradebookFilter(get().courseId, {
              ...applidFilter,
              is_applied: false
            })
          )
        )
      } catch (err) {
        set({
          flashMessages: get().flashMessages.concat([
            {
              key: `filters-create-error-${Date.now()}`,
              message: I18n.t('There was an error updating a filter.'),
              variant: 'error'
            }
          ])
        })
      }
    }

    return GradebookApi.createGradebookFilter(get().courseId, stagedFilter)
      .then(response => {
        const newFilter = deserializeFilter(response.json)
        set({
          stagedFilter: null,
          filters: get()
            .filters.map(f => ({
              ...f,
              is_applied: stagedFilter.is_applied ? false : f.is_applied
            }))
            .concat([newFilter])
            .sort(compareFilterByDate)
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

  updateFilter: async (filter: Filter) => {
    const originalFilter = get().filters.find(f => f.id === filter.id)
    const otherFilters = get().filters.filter(f => f.id !== filter.id)
    const previouslyAppliedFilters = otherFilters.filter(f => f.is_applied)

    // optimistic update
    set({
      filters: otherFilters
        .map(f => ({
          ...f,
          is_applied: filter.is_applied ? false : f.is_applied
        }))
        .concat([filter])
        .sort(compareFilterByDate)
    })

    if (filter.is_applied && previouslyAppliedFilters.length > 0) {
      try {
        await Promise.all(
          previouslyAppliedFilters.map(applidFilter =>
            GradebookApi.updateGradebookFilter(get().courseId, {
              ...applidFilter,
              is_applied: false
            })
          )
        )
      } catch (err) {
        set({
          flashMessages: get().flashMessages.concat([
            {
              key: `filters-create-error-${Date.now()}`,
              message: I18n.t('There was an error updating a filter.'),
              variant: 'error'
            }
          ])
        })
      }
    }

    try {
      const response = await GradebookApi.updateGradebookFilter(get().courseId, filter)
      const updatedFilter = deserializeFilter(response.json)
      set({
        filters: get()
          .filters.filter(f => f.id !== filter.id)
          .concat([updatedFilter])
          .sort(compareFilterByDate)
      })
    } catch (err) {
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
    }
  },

  deleteFilter: (filter: Filter) => {
    // Optimistic update
    set({filters: get().filters.filter(f => f.id !== filter.id)})

    return GradebookApi.deleteGradebookFilter(get().courseId, filter.id).catch(() => {
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
