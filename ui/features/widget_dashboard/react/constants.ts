/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import {gql} from 'graphql-tag'

const I18n = createI18nScope('widget_dashboard')

export const TAB_IDS = {
  DASHBOARD: 'dashboard',
  COURSES: 'courses',
} as const

export type TabId = (typeof TAB_IDS)[keyof typeof TAB_IDS]

export const WIDGET_TYPES = {
  COURSE_WORK_SUMMARY: 'course_work_summary',
  COURSE_WORK: 'course_work',
  COURSE_WORK_COMBINED: 'course_work_combined',
  COURSE_GRADES: 'course_grades',
  ANNOUNCEMENTS: 'announcements',
  PEOPLE: 'people',
  TODO_LIST: 'todo_list',
  RECENT_GRADES: 'recent_grades',
  PROGRESS_OVERVIEW: 'progress_overview',
} as const

export type WidgetType = (typeof WIDGET_TYPES)[keyof typeof WIDGET_TYPES]

export const LEFT_COLUMN = 1
export const RIGHT_COLUMN = 2

export const DEFAULT_WIDGET_CONFIG = {
  columns: 2,
  widgets: [
    {
      id: 'course-work-combined-widget',
      type: WIDGET_TYPES.COURSE_WORK_COMBINED,
      position: {col: 1, row: 1, relative: 1},
      title: I18n.t('Course work'),
    },
    // {
    //   id: 'todo-list-widget',
    //   type: WIDGET_TYPES.TODO_LIST,
    //   position: {col: 2, row: 1, relative: 2},
    //   title: I18n.t('To-do list'),
    // },
    {
      id: 'announcements-widget',
      type: WIDGET_TYPES.ANNOUNCEMENTS,
      position: {col: 2, row: 2, relative: 3},
      title: I18n.t('Announcements'),
    },
    {
      id: 'course-grades-widget',
      type: WIDGET_TYPES.COURSE_GRADES,
      position: {col: 1, row: 2, relative: 4},
      title: I18n.t('Course grades'),
    },
    {
      id: 'people-widget',
      type: WIDGET_TYPES.PEOPLE,
      position: {col: 2, row: 3, relative: 5},
      title: I18n.t('People'),
    },
  ],
}

// Course Grades Widget Constants
export const COURSE_GRADES_WIDGET = {
  MAX_GRID_ITEMS: 6,
  // CARD_HEIGHT: '14rem',
  GRID_COLUMNS: 2,
  GRID_COL_SPACING: 'small',
  GRID_ROW_SPACING: 'small',
  DEFAULT_COURSE_CODE: 'N/A',
  GRADING_SCHEMES: {
    LETTER: 'letter',
    PERCENTAGE: 'percentage',
  },
} as const

// Data fetching constants
export const QUERY_CONFIG = {
  STALE_TIME: {
    COURSES: 10, // minutes
    GRADES: 5, // minutes
    STATISTICS: 5, // minutes
    USERS: 10, // minutes
  },
  RETRY: {
    DISABLED: false,
    DEFAULT: 3,
  },
} as const

// Query keys
export const ANNOUNCEMENTS_PAGINATED_KEY = 'announcementsPaginated'
export const DASHBOARD_NOTIFICATIONS_KEY = 'dashboardNotifications'
export const COURSE_WORK_KEY = 'courseWork'
export const COURSE_STATISTICS_KEY = 'courseStatistics'
export const COURSE_INSTRUCTORS_PAGINATED_KEY = 'courseInstructorsPaginated'

// URL patterns
export const URL_PATTERNS = {
  GRADEBOOK: '/courses/{courseId}/gradebook',
  ALL_GRADES: '/grades',
} as const

// GraphQL mutations
export const ACCEPT_ENROLLMENT_INVITATION = gql`
  mutation AcceptEnrollmentInvitation($enrollmentUuid: String!) {
    acceptEnrollmentInvitation(input: {enrollmentUuid: $enrollmentUuid}) {
      success
      enrollment {
        id
        course {
          id
          name
        }
      }
      errors {
        message
      }
    }
  }
`

export const REJECT_ENROLLMENT_INVITATION = gql`
  mutation RejectEnrollmentInvitation($enrollmentUuid: String!) {
    rejectEnrollmentInvitation(input: {enrollmentUuid: $enrollmentUuid}) {
      success
      enrollment {
        id
      }
      errors {
        message
      }
    }
  }
`

export const UPDATE_LEARNER_DASHBOARD_TAB_SELECTION = gql`
  mutation UpdateLearnerDashboardTabSelection($tab: LearnerDashboardTabType!) {
    updateLearnerDashboardTabSelection(input: {tab: $tab}) {
      tab
      errors {
        message
      }
    }
  }
`

export const UPDATE_WIDGET_DASHBOARD_CONFIG = gql`
  mutation UpdateWidgetDashboardConfig($widgetId: String!, $filters: JSON) {
    updateWidgetDashboardConfig(input: {widgetId: $widgetId, filters: $filters}) {
      widgetId
      filters
      errors {
        message
      }
    }
  }
`

export const UPDATE_WIDGET_DASHBOARD_LAYOUT = gql`
  mutation UpdateWidgetDashboardLayout($layout: String!) {
    updateWidgetDashboardLayout(input: {layout: $layout}) {
      layout
      errors {
        message
      }
    }
  }
`
