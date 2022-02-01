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

import create from 'zustand'
import filters, {FiltersState} from './filtersState'
import modules, {ModulesState} from './modulesState'
import {RequestDispatch} from '@canvas/network'
import PerformanceControls from '../PerformanceControls'
import type {FlashMessage} from '../gradebook.d'

const defaultPerformanceControls = new PerformanceControls()

const defaultDispatch = new RequestDispatch({
  activeRequestLimit: defaultPerformanceControls.activeRequestLimit
})

type State = {
  performanceControls: PerformanceControls
  dispatch: RequestDispatch
  courseId: string
  flashMessages: FlashMessage[]
}

export type GradebookStore = State & ModulesState & FiltersState

const store = create<GradebookStore>((set, get) => ({
  performanceControls: defaultPerformanceControls,

  dispatch: defaultDispatch,

  courseId: '0',

  flashMessages: [],

  ...filters(set, get),

  ...modules(set, get)
}))

export default store
