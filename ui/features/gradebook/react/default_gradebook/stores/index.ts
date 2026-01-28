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

import {create} from 'zustand'
import filters, {type FiltersState} from './filtersState'
import modules, {type ModulesState} from './modulesState'
import students, {type StudentsState} from './studentsState'
import assignments, {type AssignmentsState} from './assignmentsState'
import sisOverrides, {type SisOverrideState} from './sisOverridesState'
import customColumns, {type CustomColumnsState} from './customColumnsState'
import finalGradeOverrides, {type FinalGradeOverrideState} from './finalGradeOverrides'
import {RequestDispatch} from '@canvas/network'
import PerformanceControls from '../PerformanceControls'
import type {FlashMessage} from '../gradebook.d'
import rubricAssessmentImport, {
  type RubricAssessmentImportState,
} from './rubricAssessmentImportState'
import rubricAssessmentExport, {
  type RubricAssessmentExportState,
} from './rubricAssessmentExportState'
import {v4 as uuidv4} from 'uuid'
import PQueue from 'p-queue'
import GRADEBOOK_GRAPHQL_CONFIG from './graphql/config'

const defaultPerformanceControls = new PerformanceControls()

const defaultDispatch = new RequestDispatch({
  activeRequestLimit: defaultPerformanceControls.activeRequestLimit,
})

type State = {
  performanceControls: PerformanceControls
  dispatch: RequestDispatch
  courseId: string
  flashMessages: FlashMessage[]
  correlationId: string
  queue: PQueue
  useQueueForRateLimiting: boolean
  returnQueueIfDefined: () => PQueue | undefined
}

export type GradebookStore = State &
  CustomColumnsState &
  FiltersState &
  ModulesState &
  StudentsState &
  AssignmentsState &
  FinalGradeOverrideState &
  SisOverrideState &
  RubricAssessmentImportState &
  RubricAssessmentExportState

const store = create<GradebookStore>((set, get) => ({
  performanceControls: defaultPerformanceControls,

  queue: new PQueue({concurrency: GRADEBOOK_GRAPHQL_CONFIG.concurrency}),

  useQueueForRateLimiting: false,

  returnQueueIfDefined: () => (get().useQueueForRateLimiting ? get().queue : undefined),

  dispatch: defaultDispatch,

  courseId: '0',

  flashMessages: [],

  // Unique identifier for tracking related API requests that belong to the same page load session.
  // Currently used to correlate REST API and GraphQL requests by appending as a custom header
  // {'Correlation-Id': 'xxx'}. This allows observability tools like Observe to group related
  // requests and calculate total/average load times for performance monitoring and REST vs
  // GraphQL comparison analysis.
  correlationId: uuidv4(),

  ...filters(set, get),

  ...modules(set, get),

  ...customColumns(set, get),

  ...students(set, get),

  ...assignments(set, get),

  ...finalGradeOverrides(set, get),

  ...sisOverrides(set, get),

  ...rubricAssessmentImport(set, get),

  ...rubricAssessmentExport(set, get),
}))

export default store
