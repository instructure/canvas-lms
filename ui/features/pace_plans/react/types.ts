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

import {BlackoutDate, Course} from './shared/types'

/* Model types */

export interface Enrollment {
  readonly id: number
  readonly full_name: string
  readonly sortable_name: string
  readonly start_at: string
  readonly completed_pace_plan_at?: string
}

export interface Enrollments {
  [key: number]: Enrollment
}

export interface Section {
  readonly id: number
  readonly name: string
  readonly start_at: string
  readonly end_at: string
}

export interface Sections {
  [key: number]: Section
}

export interface PacePlanItem {
  readonly id: number
  readonly duration: number
  readonly assignment_title: string
  readonly position: number
  readonly module_item_id: number
  readonly module_item_type: string
  readonly published: boolean
}

export interface Module {
  readonly id: string
  readonly name: string
  readonly position: number
  readonly items: PacePlanItem[]
}

export type PlanContextTypes = 'Course' | 'Section' | 'Enrollment'
export type WorkflowStates = 'unpublished' | 'published' | 'deleted'

export interface PacePlan {
  readonly id?: number | string
  readonly start_date: string
  readonly end_date: string
  readonly workflow_state: WorkflowStates
  readonly modules: Module[]
  readonly exclude_weekends: boolean
  readonly hard_end_dates?: boolean
  readonly course_id: string | number
  readonly course_section_id?: string | number
  readonly user_id?: string | number
  readonly context_type: PlanContextTypes
  readonly context_id: string | number
  readonly published_at?: string
  readonly unpublished_changes?: boolean
  readonly linked_to_parent: boolean
}

export enum PublishOptions {
  FUTURE_ONLY = 'future_only',
  ALL = 'all',
  SELECTED_SECTIONS = 'selected_sections',
  SELECTED_STUDENTS = 'selected_students',
  SINGLE_STUDENT = 'single_student'
}

/* Redux state types */

export type EnrollmentsState = Enrollments
export type SectionsState = Sections
export type PacePlansState = PacePlan

export interface UIState {
  readonly autoSaving: boolean
  readonly errorMessage: string
  readonly divideIntoWeeks: boolean
  readonly planPublishing: boolean
  readonly selectedPlanType: PlanTypes
  readonly loadingMessage: string
  readonly showLoadingOverlay: boolean
  readonly editingBlackoutDates: boolean
  readonly adjustingHardEndDatesAfter?: number
}

export interface StoreState {
  readonly pacePlan: PacePlansState
  readonly enrollments: EnrollmentsState
  readonly sections: SectionsState
  readonly ui: UIState
  readonly course: Course
  readonly blackoutDates: BlackoutDate[]
}

/* Random types  */

// Key is the pace plan item id and value is the date string
export type PacePlanItemDueDates = {[key: number]: string}

export type PlanTypes = 'template' | 'student'

/*
 * Use this when creating a payload that should map to a specific pace plan item,
 * to enforce a planId and planItemId in the payload.
 *
 * Example:
 *
 * interface SetDurationPayload extends PacePlanItemPayload { readonly duration: number }
 * const payload: SetDurationPayload = { planId: 1, planItemId: 2, duration: 10 };
 *
 */
export interface PacePlanItemPayload {
  readonly planItemId: number
}
