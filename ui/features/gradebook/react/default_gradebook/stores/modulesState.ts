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
// @ts-ignore
import I18n from 'i18n!gradebook'
import type {Module} from '../gradebook.d'
import type {GradebookStore} from './index'

export type ModulesState = {
  modules: Module[]
  isModulesLoading: boolean
  fetchModules: () => Promise<any>
}

export default (set: SetState<GradebookStore>, get: GetState<GradebookStore>): ModulesState => ({
  modules: [],

  isModulesLoading: false,

  fetchModules: () => {
    const dispatch = get().dispatch
    const courseId = get().courseId
    const contextModulesPerPage = get().performanceControls.contextModulesPerPage

    set({isModulesLoading: true})
    const url = `/api/v1/courses/${courseId}/modules`
    const params = {per_page: contextModulesPerPage}
    return dispatch
      .getDepaginated(url, params)
      .then(modules => {
        set({modules, isModulesLoading: false})
      })
      .catch(() => {
        set({
          filters: [],
          isFiltersLoading: false,
          flashMessages: get().flashMessages.concat([
            {
              key: 'modules-loading-error',
              message: I18n.t('There was an error fetching modules.'),
              variant: 'error'
            }
          ])
        })
      })
  }
})
