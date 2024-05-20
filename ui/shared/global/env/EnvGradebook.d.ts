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

import {EnvCommonNewUserTutorial} from './EnvCommon'

/**
 * Generic Gradebook environment.
 *
 * Always has new user tutorial
 * Has some combination of the the specific interfaces. Cast ENV to one of them if you need it specific
 */
export type EnvGradebook = EnvCommonNewUserTutorial &
  Partial<EnvGradebookCommon & EnvGradebookSpeedGrader>

export interface EnvGradebookCommon {
  GRADEBOOK_OPTIONS: any & {
    proxy_submissions_allowed: boolean
  }

  /**
   * From GradebooksController#set_default_gradebook_env
   */
  EMOJIS_ENABLED?: boolean
  /**
   * From GradebooksController#set_default_gradebook_env
   */
  EMOJI_DENY_LIST?: unknown

  /**
   * From GradebooksController#set_individual_gradebook_env
   */
  outcome_service_results_to_canvas: unknown

  /**
   * From GradebooksController#set_learning_mastery_env
   */
  OUTCOME_AVERAGE_CALCULATION?: unknown

  /**
   * From GradebooksController#set_learning_mastery_env
   */
  outcome_service_results_to_canvas?: unknown

  /**
   * From GradebooksController#load_grade_summary_data
   */
  course_active_grading_scheme?: any

  /**
   * From ApplicationController#set_student_context_cards_js_env
   */
  STUDENT_CONTEXT_CARDS_ENABLED: boolean

  /**
   * From ApplicationController#set_student_context_cards_js_env
   */
  student_context_card_tools: unknown
}

/**
 * GradebooksController#speed_grader
 */
export interface EnvGradebookSpeedGrader {
  SINGLE_NQ_SESSION_ENABLED: boolean
  NQ_GRADE_BY_QUESTION_ENABLED: boolean
  GRADE_BY_QUESTION: boolean
  EMOJIS_ENABLED: boolean
  EMOJI_DENY_LIST: unknown
  MANAGE_GRADES: boolean
  READ_AS_ADMIN: boolean
  CONTEXT_ACTION_SOURCE: 'speed_grader'
  can_view_audit_trail: boolean
  settings_url: string
  force_anonymous_grading: boolean
  anonymous_identities: Record<string, {name: string}>
  instructor_selectable_states: unknown
  final_grader_id: unknown
  grading_role: string
  grading_type: string
  lti_retrieve_url: string
  course_id: string
  assignment_id: string
  assignment_title: string
  custom_grade_statuses: any
  rubric: null | unknown
  nonScoringRubrics: boolean
  outcome_extra_credit_enabled: boolean
  outcome_proficiency: unknown
  group_comments_per_attempt: boolean
  can_comment_on_submission: boolean
  show_help_menu_item: true
  /**
   * i18n key: community.instructor_guide_speedgrader
   */
  help_url: string
  update_submission_grade_url: string
  can_delete_attachments: boolean
  media_comment_asset_string: string
  late_policy?: {
    late_submission_interval?: 'hour' | 'day' | string
  }
  assignment_missing_shortcut: boolean

  provisional_select_url?: string
  current_anonymous_id?: unknown

  selected_section_id: string

  new_gradebook_plagiarism_icons_enabled?: boolean

  quiz_history_url: string

  assignment_comment_library_feature_enabled: boolean

  filter_speed_grader_by_student_group_feature_enabled: boolean
  filter_speed_grader_by_student_group?: boolean
  selected_student_group?: {
    name: string
  }
  student_group_reason_for_change?: string

  update_rubric_assessment_url?: string
  RUBRIC_ASSESSMENT: {
    assessor_id?: string
    assessment_type?: string

    /**
     * This is assigned on the client, in ui/features/speed_grader/jquery/speed_grader.tsx:EG.showRubric
     */
    assessment_user_id?: string
    anonymous_id?: string
  }
}
