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

import type {GetState, SetState} from 'zustand'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {Module} from '../../../../../api.d'
import type {GradebookStore} from './index'

const I18n = useI18nScope('gradebook')

export type ModulesState = {
  modules: Module[]
  hasModules: boolean
  isModulesLoading: boolean
  fetchModules: () => Promise<any>
}

export default (set: SetState<GradebookStore>, get: GetState<GradebookStore>): ModulesState => ({
  modules: [],

  hasModules: false,

  isModulesLoading: false,

  fetchModules: () => {
    const dispatch = get().dispatch
    const courseId = get().courseId
    const contextModulesPerPage = get().performanceControls.contextModulesPerPage

    set({isModulesLoading: true})
    const url = `/api/v1/courses/${courseId}/modules`
    const params = {per_page: contextModulesPerPage}
    return dispatch
      .getDepaginated<Module[]>(url, params)
      .then(modules => {
        set({modules, isModulesLoading: false})
      })
      .catch(() => {
        set({
          filterPresets: [],
          isFiltersLoading: false,
          flashMessages: get().flashMessages.concat([
            {
              key: 'modules-loading-error',
              message: I18n.t('There was an error fetching modules.'),
              variant: 'error',
            },
          ]),
        })
      })
  },
})
