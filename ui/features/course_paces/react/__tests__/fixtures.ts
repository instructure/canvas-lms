// @ts-nocheck
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

import moment from 'moment-timezone'
import {keyBy} from 'lodash'

import {BlackoutDate, SyncState, Course} from '../shared/types'
import {
  Enrollment,
  Enrollments,
  Module,
  CoursePace,
  CoursePaceItem,
  Section,
  Sections,
  UIState,
  PaceContextsState,
  PaceContextsApiResponse,
  StoreState,
  PaceContext,
} from '../types'

window.ENV.TIMEZONE = 'America/Denver'
window.ENV.CONTEXT_TIMEZONE = 'America/Denver'
moment.tz.setDefault('America/Denver')

export const COURSE: Course = {
  id: '30',
  name: 'Neuromancy 300',
  created_at: '2021-09-01T00:00:00-06:00',
  start_at: '2021-09-01T00:00:00-06:00',
  end_at: '2021-12-31T00:00:00-07:00',
  time_zone: window.ENV.CONTEXT_TIMEZONE,
}

export const BLACKOUT_DATES: BlackoutDate[] = [
  {
    id: '30',
    course_id: COURSE.id,
    event_title: 'Spring break',
    start_date: moment('2022-03-21'),
    end_date: moment('2022-03-25'),
  },
]

export const DEFAULT_BLACKOUT_DATE_STATE = {
  syncing: SyncState.SYNCED,
  blackoutDates: BLACKOUT_DATES,
}

export const ENROLLMENT_1: Enrollment = {
  id: '20',
  course_id: COURSE.id,
  user_id: '99',
  full_name: 'Henry Dorsett Case',
  sortable_name: 'Case, Henry Dorsett',
  start_at: undefined,
  completed_course_pace_at: undefined,
}

export const ENROLLMENT_2: Enrollment = {
  id: '25',
  course_id: COURSE.id,
  user_id: '98',
  full_name: 'Molly Millions',
  sortable_name: 'Millions, Molly',
  start_at: undefined,
  completed_course_pace_at: undefined,
  avatar_url: 'molly_avatar',
}

export const ENROLLMENTS: Enrollments = keyBy([ENROLLMENT_1, ENROLLMENT_2], 'id')

export const SORTED_ENROLLMENTS: Enrollment[] = [ENROLLMENT_1, ENROLLMENT_2]

export const SECTION_1: Section = {
  id: '10',
  course_id: COURSE.id,
  name: 'Hackers',
  start_at: undefined,
  end_at: undefined,
}

export const SECTION_2: Section = {
  id: '15',
  course_id: COURSE.id,
  name: 'Mercenaries',
  start_at: undefined,
  end_at: undefined,
}

export const SECTIONS: Sections = keyBy([SECTION_1, SECTION_2], 'id')

export const SORTED_SECTIONS: Section[] = [SECTION_1, SECTION_2]

export const PACE_ITEM_1: CoursePaceItem = {
  id: '50',
  duration: 2,
  assignment_title: 'Basic encryption/decryption',
  assignment_link: `/courses/${COURSE.id}/modules/items/50`,
  points_possible: 100,
  position: 1,
  module_item_id: '60',
  module_item_type: 'Assignment',
  published: true,
}

export const PACE_ITEM_2: CoursePaceItem = {
  id: '51',
  duration: 5,
  assignment_title: 'Being 1337',
  assignment_link: `/courses/${COURSE.id}/modules/items/51`,
  points_possible: 80,
  position: 2,
  module_item_id: '61',
  module_item_type: 'Discussion',
  published: false,
}

export const PACE_ITEM_3: CoursePaceItem = {
  id: '52',
  duration: 3,
  assignment_title: 'What are laws, anyway?',
  assignment_link: `/courses/${COURSE.id}/modules/items/52`,
  points_possible: 1,
  position: 1,
  module_item_id: '62',
  module_item_type: 'Quiz',
  published: true,
}

export const PACE_MODULE_1: Module = {
  id: '40',
  name: 'How 2 B A H4CK32',
  position: 1,
  items: [PACE_ITEM_1, PACE_ITEM_2],
}

export const PACE_MODULE_2: Module = {
  id: '45',
  name: 'Intro to Corporate Espionage',
  position: 2,
  items: [PACE_ITEM_3],
}

export const PRIMARY_PACE: CoursePace = {
  id: '1',
  name: 'Course 1',
  course_id: COURSE.id,
  course_section_id: undefined,
  user_id: undefined,
  context_type: 'Course',
  context_id: COURSE.id,
  start_date: '2021-09-01',
  start_date_context: 'course',
  end_date: '2021-12-15',
  end_date_context: 'course',
  workflow_state: 'active',
  exclude_weekends: true,
  modules: [PACE_MODULE_1, PACE_MODULE_2],
  // @ts-expect-error
  course: undefined,
  compressed_due_dates: undefined,
  updated_at: '',
}

export const HEADING_STATS_API_RESPONSE = {
  pace_contexts: [
    {
      name: 'Defense Against the Dark Arts',
      associated_section_count: 3,
      associated_student_count: 30,
      applied_pace: {duration: 65},
    },
  ],
}

export const COURSE_PACE_CONTEXT: PaceContext = {
  name: 'Course 1',
  type: 'Course',
  item_id: '78',
  associated_section_count: 1,
  associated_student_count: 31,
  applied_pace: {
    name: 'Course 1',
    type: 'Course',
    duration: 6,
    last_modified: '2022-10-17T23:12:24Z',
  },
}

export const PACE_CONTEXTS_SECTIONS_RESPONSE: PaceContextsApiResponse = {
  pace_contexts: [
    {
      name: 'A-C',
      type: 'CourseSection',
      item_id: '78',
      associated_section_count: 1,
      associated_student_count: 21,
      applied_pace: {
        name: 'Main',
        type: 'Course',
        duration: 6,
        last_modified: '2022-10-17T23:12:24Z',
      },
    },
    {
      name: 'D-F',
      type: 'CourseSection',
      item_id: '79',
      associated_section_count: 1,
      associated_student_count: 1,
      applied_pace: {
        name: 'LS3432',
        type: 'Course',
        duration: 6,
        last_modified: '2022-10-17T23:12:24Z',
      },
    },
    {
      name: 'G-K',
      type: 'CourseSection',
      item_id: '80',
      associated_section_count: 1,
      associated_student_count: 1,
      applied_pace: {
        name: 'LS3432',
        type: 'Course',
        duration: 6,
        last_modified: '2022-10-17T23:12:24Z',
      },
    },
  ],
  total_entries: 3,
}

export const PACE_CONTEXTS_SECTIONS_SEARCH_RESPONSE: PaceContextsApiResponse = {
  pace_contexts: [
    {
      name: 'A-C',
      type: 'CourseSection',
      item_id: '78',
      associated_section_count: 1,
      associated_student_count: 21,
      applied_pace: {
        name: 'Main',
        type: 'Course',
        duration: 6,
        last_modified: '2022-10-17T23:12:24Z',
      },
    },
  ],
  total_entries: 1,
}

export const PACE_CONTEXTS_STUDENTS_RESPONSE: PaceContextsApiResponse = {
  pace_contexts: [
    {
      name: 'Jon',
      type: 'StudentEnrollment',
      item_id: '788',
      associated_section_count: 1,
      associated_student_count: 1,
      applied_pace: {
        name: 'J-M',
        type: 'StudentEnrollment',
        duration: 6,
        last_modified: '2022-10-17T23:12:24Z',
      },
    },
    {
      name: 'Peter',
      type: 'StudentEnrollment',
      item_id: '789',
      associated_section_count: 1,
      associated_student_count: 1,
      applied_pace: {
        name: 'LS3432',
        type: 'Course',
        duration: 6,
        last_modified: '2022-10-17T23:12:24Z',
      },
    },
    {
      name: 'Mike',
      type: 'StudentEnrollment',
      item_id: '790',
      associated_section_count: 1,
      associated_student_count: 1,
      applied_pace: {
        name: 'LS3432',
        type: 'Course',
        duration: 6,
        last_modified: '2022-10-17T23:12:24Z',
      },
    },
    {
      name: 'Alex',
      type: 'StudentEnrollment',
      item_id: '791',
      associated_section_count: 1,
      associated_student_count: 1,
      applied_pace: {
        name: 'LS3432',
        type: 'Course',
        duration: 6,
        last_modified: '2022-10-17T23:12:24Z',
      },
    },
  ],
  total_entries: 4,
}

export const SECTION_PACE: CoursePace = {
  id: '2',
  course_id: COURSE.id,
  course_section_id: SECTION_1.id,
  user_id: undefined,
  context_type: 'Section',
  context_id: SECTION_1.id,
  start_date: '2021-09-15',
  start_date_context: 'course',
  end_date: '2021-12-15',
  end_date_context: 'course',
  workflow_state: 'active',
  exclude_weekends: false,
  modules: [PACE_MODULE_1, PACE_MODULE_2],
  // @ts-expect-error
  course: undefined,
  compressed_due_dates: undefined,
  updated_at: '',
}

export const STUDENT_PACE: CoursePace = {
  id: '3',
  course_id: COURSE.id,
  course_section_id: undefined,
  user_id: ENROLLMENT_1.user_id,
  context_type: 'Enrollment',
  context_id: ENROLLMENT_1.user_id,
  start_date: '2021-10-01',
  start_date_context: 'user',
  end_date: '2021-12-15',
  end_date_context: 'user',
  workflow_state: 'active',
  exclude_weekends: true,
  modules: [PACE_MODULE_1, PACE_MODULE_2],
  // @ts-expect-error
  course: undefined,
  compressed_due_dates: undefined,
  updated_at: '',
}

export const PACE_CONTEXTS_DEFAULT_STATE: PaceContextsState = {
  selectedContextType: 'section',
  selectedContext: PACE_CONTEXTS_SECTIONS_RESPONSE.pace_contexts[0],
  entries: PACE_CONTEXTS_SECTIONS_RESPONSE.pace_contexts,
  pageCount: 1,
  page: 1,
  entriesPerRequest: 10,
  isLoading: true,
  searchTerm: '',
  order: 'asc',
  sortBy: 'name',
  isLoadingDefault: false,
  defaultPaceContext: COURSE_PACE_CONTEXT,
  contextsPublishing: [],
}

export const PROGRESS_RUNNING = {
  id: '900',
  completion: 25,
  context_id: '30',
  message: undefined,
  workflow_state: 'running',
  url: '/api/v1/progress/900',
}

export const PROGRESS_FAILED = {
  id: '901',
  completion: undefined,
  message: 'Something went wrong!',
  workflow_state: 'failed',
  url: '/api/v1/progress/901',
}

export const DEFAULT_UI_STATE: UIState = {
  autoSaving: false,
  divideIntoWeeks: true,
  editingBlackoutDates: false,
  errors: {},
  loadingMessage: '',
  responsiveSize: 'large' as const,
  selectedContextId: '30',
  selectedContextType: 'Course' as const,
  showLoadingOverlay: false,
  showPaceModal: false,
  showProjections: true,
  syncing: 0,
}

export const DEFAULT_STORE_STATE: StoreState = {
  blackoutDates: DEFAULT_BLACKOUT_DATE_STATE,
  course: COURSE,
  enrollments: ENROLLMENTS,
  coursePace: {...PRIMARY_PACE},
  sections: SECTIONS,
  original: {coursePace: PRIMARY_PACE, blackoutDates: BLACKOUT_DATES},
  paceContexts: PACE_CONTEXTS_DEFAULT_STATE,
  ui: DEFAULT_UI_STATE,
}
