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

import {keyBy} from 'lodash'

import {BlackoutDate, Course} from '../shared/types'
import {
  Enrollment,
  Enrollments,
  EnrollmentsState,
  Module,
  PacePlan,
  PacePlanItem,
  PacePlansState,
  Section,
  Sections,
  SectionsState,
  UIState
} from '../types'

export const BLACKOUT_DATES: BlackoutDate[] = []

export const COURSE: Course = {
  id: '30',
  name: 'Neuromancy 300',
  start_at: '2021-09-01',
  end_at: '2021-12-15'
}

export const ENROLLMENT_1: Enrollment = {
  id: '20',
  course_id: COURSE.id,
  user_id: '99',
  full_name: 'Henry Dorsett Case',
  sortable_name: 'Case, Henry Dorsett',
  start_at: undefined,
  completed_pace_plan_at: undefined
}

export const ENROLLMENT_2: Enrollment = {
  id: '25',
  course_id: COURSE.id,
  user_id: '98',
  full_name: 'Molly Millions',
  sortable_name: 'Millions, Molly',
  start_at: undefined,
  completed_pace_plan_at: undefined
}

export const ENROLLMENTS: Enrollments = keyBy([ENROLLMENT_1, ENROLLMENT_2], 'id')

export const SORTED_ENROLLMENTS: Enrollment[] = [ENROLLMENT_1, ENROLLMENT_2]

export const SECTION_1: Section = {
  id: '10',
  course_id: COURSE.id,
  name: 'Hackers',
  start_at: undefined,
  end_at: undefined
}

export const SECTION_2: Section = {
  id: '15',
  course_id: COURSE.id,
  name: 'Mercenaries',
  start_at: undefined,
  end_at: undefined
}

export const SECTIONS: Sections = keyBy([SECTION_1, SECTION_2], 'id')

export const SORTED_SECTIONS: Section[] = [SECTION_1, SECTION_2]

export const PLAN_ITEM_1: PacePlanItem = {
  id: '50',
  duration: 2,
  assignment_title: 'Basic encryption/decryption',
  position: 1,
  module_item_id: '60',
  module_item_type: 'Assignment',
  published: true
}

export const PLAN_ITEM_2: PacePlanItem = {
  id: '51',
  duration: 5,
  assignment_title: 'Being 1337',
  position: 2,
  module_item_id: '61',
  module_item_type: 'Discussion',
  published: false
}

export const PLAN_ITEM_3: PacePlanItem = {
  id: '52',
  duration: 3,
  assignment_title: 'What are laws, anyway?',
  position: 1,
  module_item_id: '62',
  module_item_type: 'Quiz',
  published: true
}

export const PLAN_MODULE_1: Module = {
  id: '40',
  name: 'How 2 B A H4CK32',
  position: 1,
  items: [PLAN_ITEM_1, PLAN_ITEM_2]
}

export const PLAN_MODULE_2: Module = {
  id: '45',
  name: 'Intro to Corporate Espionage',
  position: 2,
  items: [PLAN_ITEM_3]
}

export const PRIMARY_PLAN: PacePlan = {
  id: '1',
  course_id: COURSE.id,
  course_section_id: undefined,
  user_id: undefined,
  context_type: 'Course',
  context_id: COURSE.id,
  start_date: '2021-09-01',
  end_date: '2021-12-15',
  workflow_state: 'active',
  exclude_weekends: true,
  hard_end_dates: true,
  modules: [PLAN_MODULE_1, PLAN_MODULE_2]
}

export const SECTION_PLAN: PacePlan = {
  id: '2',
  course_id: COURSE.id,
  course_section_id: SECTION_1.id,
  user_id: undefined,
  context_type: 'Section',
  context_id: SECTION_1.id,
  start_date: '2021-09-15',
  end_date: '2021-12-15',
  workflow_state: 'active',
  exclude_weekends: false,
  hard_end_dates: true,
  modules: [PLAN_MODULE_1, PLAN_MODULE_2]
}

export const STUDENT_PLAN: PacePlan = {
  id: '3',
  course_id: COURSE.id,
  course_section_id: undefined,
  user_id: ENROLLMENT_1.user_id,
  context_type: 'Enrollment',
  context_id: ENROLLMENT_1.user_id,
  start_date: '2021-10-01',
  end_date: '2021-12-15',
  workflow_state: 'active',
  exclude_weekends: true,
  hard_end_dates: true,
  modules: [PLAN_MODULE_1, PLAN_MODULE_2]
}

export interface DefaultStoreState {
  readonly pacePlan?: PacePlansState
  readonly enrollments?: EnrollmentsState
  readonly sections?: SectionsState
  readonly ui?: UIState
  readonly course?: Course
  readonly blackoutDates?: BlackoutDate[]
}

export const DEFAULT_STORE_STATE: DefaultStoreState = {
  blackoutDates: BLACKOUT_DATES,
  course: COURSE,
  enrollments: ENROLLMENTS,
  pacePlan: {...PRIMARY_PLAN, originalPlan: PRIMARY_PLAN},
  sections: SECTIONS
}
