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

/**
 * Assignments environment data.
 *
 * From assignments_controller.rb
 */
export type EnvAssignments = Partial<EnvAssignmentsA2StudentView> &
  Partial<EnvAssignmentsDefaultToolInfo>

/**
 * A2-related ENV variables.
 *
 * Ideally, the optionality of these would match the ruby, but that's
 * hard to follow, so no guarantee.
 *
 * From AssignmentsController#render_a2_student_view
 */
export interface EnvAssignmentsA2StudentView {
  a2_student_view: boolean
  peer_review_mode_enabled: boolean
  peer_display_name: string
  originality_reports_for_a2_enabled: boolean
  restrict_quantitative_data: boolean
  grading_scheme: any

  // Peer review data
  peer_review_available: boolean
  reviewee_id?: string | number
  anonymous_asset_id?: string | number
  REVIEWER_SUBMISSION_ID?: string | number

  belongs_to_unpublished_module: boolean

  ASSIGNMENT_ID: string | number
  CONFETTI_ENABLED: boolean
  EMOJIS_ENABLED: boolean
  EMOJI_DENY_LIST: any[]
  COURSE_ID: string | number
  ISOBSERVER: boolean
  ORIGINALITY_REPORTS_FOR_A2: boolean
  PREREQS: any
  SUBMISSION_ID: string | number
  DUE_DATE_REQUIRED_FOR_ACCOUNT?: boolean
  SECTION_LIST?: EnvSection[]
  HAS_GRADING_PERIODS?: boolean
  active_grading_periods?: any[]
}

/**
 * From From AssignmentsController#set_default_tool_env!
 */
export interface EnvAssignmentsDefaultToolInfo {
  DEFAULT_ASSIGNMENT_TOOL_URL?: string
  DEFAULT_ASSIGNMENT_TOOL_NAME?: string
  DEFAULT_ASSIGNMENT_TOOL_BUTTON_TEXT?: string
  DEFAULT_ASSIGNMENT_TOOL_INFO_MESSAGE?: string
}

export interface EnvSection {
  end_at: string | null
  id: string
  override_course_and_term_dates: boolean | null
  start_at: string | null
}
