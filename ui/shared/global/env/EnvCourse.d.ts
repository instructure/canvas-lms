/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {Course} from '../../../features/course_paces/react/shared/types'

export type EnvCourse = EnvCourseCommon & Partial<EnvCourseCommon>

/**
 * Course related ENV
 */
export interface EnvCourseCommon {
  COURSE: Course

  /**
   * From CoursesController#index
   */
  CREATE_COURSES_PERMISSIONS?: {
    PERMISSION: boolean
    RESTRICT_TO_MCC_ACCOUNT: boolean
  }

  /**
   * From CoursesController#statistics
   */
  RECENT_STUDENTS_URL?: string
}

/**
 * Course settings page related variables
 *
 * From CoursesController#settings
 */
export interface EnvCourseSettings {
  COURSE_ID: string
  /**
   * From "/api/v1/courses/#{@context.id}/users"
   */
  USERS_URL: string
  ALL_ROLES: Array<{
    base_role_name: string
    name: string
    label: string
    plural_label: string
    id: string
    custom_roles: unknown[]
    count: number
  }>
  /**
   * From "/courses/#{@context.id}"
   */
  COURSE_ROOT_URL: string

  /**
   * Example: https://school.instructure.com/search/recipients"
   */
  SEARCH_URL: string

  /**
   *
   */
  CONTEXTS: {
    courses: Record<
      string,
      {
        id: string
        url: string
        name: string
        type: string
        term: unknown | null
        state: string
        available: boolean
        default_section_id: string
        permissions: Record<string, boolean>
      }
    >
    groups: Record<string, {}>
    sections: Record<
      string,
      {
        id: string
        name: string
        type: string
        term: unknown | null
        state: string
        parent: {
          course: number
        }
        context_name: string
      }
    >
  }
  USER_PARAMS: {
    include: Array<'email' | 'enrollments' | 'locked' | 'observed_users' | string>
  }
  PERMISSIONS: {
    can_manage_courses: boolean
    manage_students: boolean
    manage_account_settings: boolean
    manage_feature_flags: boolean
    manage: boolean
    edit_course_availability: boolean

    can_allow_course_admin_actions: boolean
    manage_admin_users: boolean

    add_tool_manually: boolean
    edit_tool_manually: boolean
    delete_tool_manually: boolean
  }
  APP_CENTER: {
    enabled: boolean
  }

  /**
   * Example: "/courses/119048/lti/tool_proxy_registration",
   */
  LTI_LAUNCH_URL: string

  /**
   * Example: "https://school.instructure.com/courses/119048/external_tools",
   */
  EXTERNAL_TOOLS_CREATE_URL: string

  /**
   * Example: "https://school.instructure.com/api/lti/courses/119048/developer_keys/:developer_key_id/tool_configuration",
   */
  TOOL_CONFIGURATION_SHOW_URL: string
  MEMBERSHIP_SERVICE_FEATURE_FLAG_ENABLED: boolean
  /**
   * Example: "/courses/119048"
   */
  CONTEXT_BASE_URL: string

  COURSE_COLOR: false | string
  PUBLISHING_ENABLED: boolean
  COURSE_COLORS_ENABLED: boolean
  COURSE_VISIBILITY_OPTION_DESCRIPTIONS: {
    course: string
    institution: string
    public: string
  }
  STUDENTS_ENROLLMENT_DATES: unknown | null
  DEFAULT_TERM_DATES: {
    start_at: unknown | null
    end_at: unknown | null
  }
  COURSE_DATES: {
    start_at: unknown | null
    end_at: unknown | null
  }
  RESTRICT_STUDENT_PAST_VIEW_LOCKED: false
  RESTRICT_STUDENT_FUTURE_VIEW_LOCKED: false
  RESTRICT_QUANTITATIVE_DATA: false
  PREVENT_COURSE_AVAILABILITY_EDITING_BY_TEACHERS: unknown | null
  MANUAL_MSFT_SYNC_COOLDOWN: number
  MSFT_SYNC_ENABLED: boolean
  MSFT_SYNC_CAN_BYPASS_COOLDOWN: boolean
  MSFT_SYNC_MAX_ENROLLMENT_MEMBERS: number
  MSFT_SYNC_MAX_ENROLLMENT_OWNERS: number
  COURSE_PACES_ENABLED: false

  NEW_USER_TUTORIALS?: {
    is_enabled: boolean
  }

  IS_MASTER_COURSE: boolean
  /**
   * Example: Cannot have a blueprint course with students
   */
  DISABLED_BLUEPRINT_MESSAGE: string

  BLUEPRINT_RESTRICTIONS: {
    content: boolean
  }

  USE_BLUEPRINT_RESTRICTIONS_BY_OBJECT_TYPE: boolean
  BLUEPRINT_RESTRICTIONS_BY_OBJECT_TYPE: Record<string, boolean>

  SHOW_ANNOUNCEMENTS?: boolean | null
  ANNOUNCEMENT_LIMIT?: number | null
}
