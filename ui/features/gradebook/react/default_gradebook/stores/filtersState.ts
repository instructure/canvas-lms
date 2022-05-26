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
import type {FilterCondition, Filter} from '../gradebook.d'
import {compareFilterByDate, deserializeFilter, doFilterConditionsMatch} from '../Gradebook.utils'
import GradebookApi from '../apis/GradebookApi'
import type {GradebookStore} from './index'

const I18n = useI18nScope('gradebook')

export type FiltersState = {
  appliedFilterConditions: FilterCondition[]
  filters: Filter[]
  stagedFilterConditions: FilterCondition[]
  isFiltersLoading: boolean

  applyConditions: (conditions: FilterCondition[]) => Promise<void>
  initializeStagedFilter: (InitialColumnFilterSettings, InitialRowFilterSettings) => void
  fetchFilters: () => Promise<void>
  saveStagedFilter: (name: string) => Promise<void>
  updateStagedFilter: (filter: FilterCondition[]) => void
  deleteStagedFilter: () => void
  updateFilter: (filter: Filter) => Promise<void>
  deleteFilter: (filter: Filter) => Promise<any>
}

export type InitialColumnFilterSettings = {
  assignment_group_id: null | string
  context_module_id: null | string
  grading_period_id: null | string
  submissions: null | 'has-submissions' | 'has-ungraded-submissions'
}

export type InitialRowFilterSettings = {
  section_id: null | string
  student_group_id: null | string
}

export default (set: SetState<GradebookStore>, get: GetState<GradebookStore>): FiltersState => ({
  appliedFilterConditions: [],

  filters: [],

  stagedFilterConditions: [],

  isFiltersLoading: false,

  applyConditions: async (appliedFilterConditions: FilterCondition[]) => {
    set({appliedFilterConditions})
  },

  initializeStagedFilter: (
    initialRowFilterSettings: InitialRowFilterSettings,
    initialColumnFilterSettings: InitialColumnFilterSettings
  ) => {
    const conditions: FilterCondition[] = []

    if (initialRowFilterSettings.section_id) {
      conditions.push({
        id: uuid.v4(),
        value: initialRowFilterSettings.section_id,
        type: 'section',
        created_at: new Date().toISOString()
      })
    }

    if (initialRowFilterSettings.student_group_id) {
      conditions.push({
        id: uuid.v4(),
        value: initialRowFilterSettings.student_group_id,
        type: 'student-group',
        created_at: new Date().toISOString()
      })
    }

    if (
      initialColumnFilterSettings.assignment_group_id &&
      initialColumnFilterSettings.assignment_group_id !== '0'
    ) {
      conditions.push({
        id: uuid.v4(),
        value: initialColumnFilterSettings.assignment_group_id,
        type: 'assignment-group',
        created_at: new Date().toISOString()
      })
    }

    if (
      ['has-ungraded-submissions', 'has-submissions'].includes(
        initialColumnFilterSettings.submissions || ''
      )
    ) {
      conditions.push({
        id: uuid.v4(),
        value: initialColumnFilterSettings.submissions || undefined,
        type: 'submissions',
        created_at: new Date().toISOString()
      })
    }

    if (
      initialColumnFilterSettings.context_module_id &&
      initialColumnFilterSettings.context_module_id !== '0'
    ) {
      conditions.push({
        id: uuid.v4(),
        value: initialColumnFilterSettings.context_module_id,
        type: 'module',
        created_at: new Date().toISOString()
      })
    }

    if (
      initialColumnFilterSettings.grading_period_id &&
      initialColumnFilterSettings.grading_period_id !== '0'
    ) {
      conditions.push({
        id: uuid.v4(),
        value: initialColumnFilterSettings.grading_period_id,
        type: 'grading-period',
        created_at: new Date().toISOString()
      })
    }

    const savedFilterAlreadyMatches = get().filters.some(filter =>
      doFilterConditionsMatch(filter.conditions, conditions)
    )

    set({
      appliedFilterConditions: conditions,
      stagedFilterConditions: !savedFilterAlreadyMatches ? conditions : []
    })
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

  deleteStagedFilter: () => {
    const appliedFilterConditions = get().appliedFilterConditions
    const isFilterApplied = doFilterConditionsMatch(
      get().stagedFilterConditions,
      appliedFilterConditions
    )
    set({
      stagedFilterConditions: [],
      appliedFilterConditions: isFilterApplied ? [] : appliedFilterConditions
    })
  },

  updateStagedFilter: (newStagedFilterConditions: FilterCondition[]) => {
    const appliedFilterConditions = get().appliedFilterConditions
    const stagedFilterConditions = get().stagedFilterConditions
    const isFilterApplied = doFilterConditionsMatch(stagedFilterConditions, appliedFilterConditions)

    set({
      stagedFilterConditions: newStagedFilterConditions,
      appliedFilterConditions: isFilterApplied
        ? newStagedFilterConditions
        : get().appliedFilterConditions
    })
  },

  saveStagedFilter: async (name: string) => {
    const stagedFilterConditions = get().stagedFilterConditions
    if (!stagedFilterConditions.length) return
    const originalFilters = get().filters
    const stagedFilter = {
      id: uuid.v4(),
      name,
      conditions: stagedFilterConditions,
      created_at: new Date().toISOString()
    }

    // optimistic update
    set({
      filters: get().filters.concat([stagedFilter]).sort(compareFilterByDate),
      stagedFilterConditions: []
    })

    return GradebookApi.createGradebookFilter(get().courseId, stagedFilter)
      .then(response => {
        const newFilter = deserializeFilter(response.json)
        set({
          stagedFilterConditions: [],
          filters: originalFilters.concat([newFilter]).sort(compareFilterByDate)
        })
      })
      .catch(() => {
        set({
          stagedFilterConditions,
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
    const appliedFilterConditions = get().appliedFilterConditions

    const isFilterApplied = doFilterConditionsMatch(
      originalFilter?.conditions || [],
      appliedFilterConditions
    )

    // optimistic update
    set({
      filters: otherFilters.concat([filter]).sort(compareFilterByDate),
      appliedFilterConditions: isFilterApplied ? filter.conditions : appliedFilterConditions
    })

    try {
      const response = await GradebookApi.updateGradebookFilter(get().courseId, filter)
      const updatedFilter = deserializeFilter(response.json)
      set({
        filters: get()
          .filters.filter(f => f.id !== filter.id)
          .concat([updatedFilter])
          .sort(compareFilterByDate),
        appliedFilterConditions: isFilterApplied
          ? updatedFilter.conditions
          : appliedFilterConditions
      })
    } catch (err) {
      // rewind
      if (originalFilter) {
        set({
          filters: get()
            .filters.filter(f => f.id !== filter.id)
            .concat([originalFilter])
            .sort(compareFilterByDate),
          appliedFilterConditions
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
    const appliedFilterConditions = get().appliedFilterConditions
    const isFilterApplied = doFilterConditionsMatch(
      filter.conditions,
      get().appliedFilterConditions
    )

    // Optimistic update
    set({
      filters: get().filters.filter(f => f.id !== filter.id),
      appliedFilterConditions: isFilterApplied ? [] : appliedFilterConditions
    })

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
        ]),
        appliedFilterConditions
      })
    })
  }
})
