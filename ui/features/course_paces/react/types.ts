/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import moment from 'moment'
import type {BlackoutDateState, BlackoutDate, Course} from './shared/types'

/* Model types */

export interface Enrollment {
  readonly id: string
  readonly course_id: string
  readonly user_id: string
  readonly full_name: string
  readonly sortable_name: string
  readonly start_at?: string
  readonly completed_course_pace_at?: string
  readonly avatar_url?: string
  readonly section_id?: string
}

export interface Enrollments {
  [key: number]: Enrollment
}

export interface Section {
  readonly id: string
  readonly course_id: string
  readonly name: string
  readonly start_at?: string
  readonly end_at?: string
}

export interface Sections {
  [key: number]: Section
}

export interface CoursePaceItem {
  readonly id: string
  readonly duration: number
  readonly assignment_title: string
  readonly assignment_link: string
  readonly points_possible?: number | null
  readonly position: number
  readonly module_item_id: string
  readonly module_item_type: string
  readonly published: boolean
  compressed_due_date?: string
}

export interface Module {
  readonly id: string
  readonly name: string
  readonly position: number
  readonly items: CoursePaceItem[]
}

interface ItemDueDate {
  date: moment.Moment
  type: 'assignment' | 'blackout_date'
}

// after module items are merged with their due dates and blackout dates
export type CoursePaceItemWithDate = ItemDueDate & (CoursePaceItem | BlackoutDate)

export interface ModuleWithDueDates extends Module {
  moduleKey: string
  itemsWithDates: CoursePaceItemWithDate[]
}

export type PaceContextTypes = 'Course' | 'Section' | 'Enrollment'
export type APIPaceContextTypes = 'course' | 'section' | 'student_enrollment'
export type WorkflowStates = 'unpublished' | 'active' | 'deleted'
export type ProgressStates = 'queued' | 'running' | 'completed' | 'failed'
export type ContextTypes = 'user' | 'course' | 'term' | 'hypothetical'
export type OptionalDate = string | null | undefined
export interface PaceDuration {
  weeks: number
  days: number
}

export interface CoursePace {
  readonly id?: string
  readonly start_date: string
  readonly start_date_context: ContextTypes
  readonly end_date: OptionalDate
  readonly end_date_context: ContextTypes
  readonly workflow_state: WorkflowStates
  readonly modules: Module[]
  readonly exclude_weekends: boolean
  readonly course: Course
  readonly course_id: string
  readonly course_section_id?: string
  readonly user_id?: string
  readonly context_type: PaceContextTypes
  readonly context_id: string
  readonly published_at?: string
  readonly compressed_due_dates: CoursePaceItemDueDates | undefined
  readonly updated_at: string
  readonly name?: string
}

export interface Progress {
  readonly id: string
  readonly completion?: number
  readonly message?: string
  readonly created_at: string
  readonly updated_at: string
  readonly workflow_state: ProgressStates
  readonly url: string
}

/* Redux state types */

export type EnrollmentsState = Enrollments
export type CoursePacesState = CoursePace & {
  publishingProgress?: Progress
}
export type SectionsState = Sections
export type ResponsiveSizes = 'small' | 'large'
export type CategoryErrors = {[category: string]: string}
export type OriginalState = {
  coursePace: CoursePace
  blackoutDates: BlackoutDate[]
}

export interface UIState {
  readonly autoSaving: boolean
  readonly syncing: number
  readonly errors: CategoryErrors
  readonly divideIntoWeeks: boolean
  readonly selectedContextType: PaceContextTypes
  readonly selectedContextId: string
  readonly loadingMessage: string
  readonly responsiveSize: ResponsiveSizes
  readonly outerResponsiveSize: ResponsiveSizes
  readonly showLoadingOverlay: boolean
  readonly showPaceModal: boolean
  readonly showProjections: boolean
  readonly editingBlackoutDates: boolean
  readonly blueprintLocked?: boolean
}

export type SortableColumn = 'name' | null
export type OrderType = 'asc' | 'desc'

export interface PaceContextsState {
  readonly selectedContextType: APIPaceContextTypes
  readonly selectedContext: PaceContext | null
  readonly entries: PaceContext[]
  readonly page: number
  readonly pageCount: number
  readonly entriesPerRequest: number
  readonly isLoading: boolean
  readonly defaultPaceContext: PaceContext | null
  readonly isLoadingDefault: false
  readonly searchTerm: string
  readonly sortBy: SortableColumn
  readonly order: OrderType
  readonly contextsPublishing: PaceContextProgress[]
}

export interface StoreState {
  readonly original: OriginalState
  readonly coursePace: CoursePacesState
  readonly enrollments: EnrollmentsState
  readonly sections: SectionsState
  readonly ui: UIState
  readonly course: Course
  readonly blackoutDates: BlackoutDateState
  readonly paceContexts: PaceContextsState
}

export interface Pace {
  name: string
  type: string
  last_modified: string
  duration: number
}

export interface PaceContext {
  name: string
  type: string
  item_id: string
  associated_section_count: number
  associated_student_count: number
  applied_pace: Pace | null
}

export interface PaceContextProgress {
  progress_context_id: string
  pace_context: PaceContext
  polling: boolean
}

export interface PaceContextsApiResponse {
  pace_contexts: PaceContext[]
  total_entries: number
}

export interface PaceContextsAsyncActionPayload {
  result: PaceContextsApiResponse | PaceContext
  page?: number
  searchTerm?: string
  sortBy?: SortableColumn
  orderType?: OrderType
}

/* Random types  */

// Key is the course pace item id and value is the date string
export type CoursePaceItemDueDates = {[key: number]: string}

/*
 * Use this when creating a payload that should map to a specific course pace item,
 * to enforce a paceId and paceItemId in the payload.
 *
 * Example:
 *
 * interface SetDurationPayload extends CoursePaceItemPayload { readonly duration: number }
 * const payload: SetDurationPayload = { paceId: 1, paceItemId: 2, duration: 10 };
 *
 */
export interface CoursePaceItemPayload {
  readonly paceItemId: number
}
