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

/**
 * New Quizzes context data for native (non-LTI) mode.
 * These parameters are provided directly via js_env instead of LTI launch.
 * Mirrors LTI custom_params structure for compatibility with existing tools.
 */
export interface NewQuizzesContext {
  params: {
    // Canvas instance
    custom_canvas_api_domain?: string

    // LTI Resource Link ID (for assignment lookup)
    lti_resource_link_id?: string

    // Assignment context
    custom_canvas_assignment_id?: string | number
    custom_canvas_assignment_title?: string
    custom_canvas_assignment_due_at?: string
    custom_canvas_assignment_unlock_at?: string
    custom_canvas_assignment_lock_at?: string
    custom_canvas_assignment_points_possible?: number | string
    custom_canvas_assignment_anonymous_grading?: boolean | string
    custom_canvas_assignment_omit_from_final_grade?: boolean | string

    // Course context
    custom_canvas_course_id?: string | number
    custom_canvas_course_uuid?: string
    custom_canvas_course_name?: string
    custom_canvas_course_workflow_state?: string

    // User context
    custom_canvas_user_id?: string | number
    custom_canvas_user_uuid?: string
    custom_canvas_user_login_id?: string
    custom_canvas_user_student_view?: boolean | string
    user_email?: string
    user_image?: string

    // Enrollment state and permissions
    custom_canvas_enrollment_state?: string
    custom_canvas_permissions?: string

    // Tool context
    custom_canvas_tool_id?: string | number

    // Locale and formatting
    custom_canvas_timezone_name?: string
    custom_canvas_high_contrast_setting?: boolean | string

    // LIS context (IMS LTI compatibility)
    lis_person_contact_email_primary?: string
    lis_person_name_full?: string

    // Context information
    context_id?: string
    context_title?: string
    context_label?: string

    // Backend configuration
    backend_url?: string

    // Launch configuration response from quiz_lti
    access_token?: string
    launch_token?: string
    launch_url?: string
    assignment_id?: string | number
    current_user?: {
      full_name?: string
      email?: string
      uuid?: string
      enrollment_names?: string[]
      enable_rum?: boolean
      is_test_student?: boolean
      account_name?: string
      account_uuid?: string
      bank_admin?: boolean
      can_share_banks_with_subaccounts?: boolean
      is_site_admin?: boolean
      roles?: string[]
    }
    item_banks_scope?: {
      type?: string
      uuid?: string
    }
    course_workflow_state?: string
    timezone?: string
    high_contrast?: boolean
    platform?: string
    lang?: string
  }
  signature: string
}

export interface EnvNewQuizzes {
  NEW_QUIZZES: NewQuizzesContext
}
