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

export type EnvAccounts = Partial<EnvAccountsAdminTools & EnvAccountsSisImport>

/**
 * From AccountsController#admin_tools
 */
export interface EnvAccountsAdminTools {
  ROOT_ACCOUNT_NAME: string
  ACCOUNT_ID: string
  CONTEXT_BASE_URL: string
  EARLY_ACCESS_PROGRAM: boolean
  PERMISSIONS: {
    can_manage_user_details: boolean
    can_allow_course_admin_actions: boolean
    can_create_enrollments: boolean
    can_create_users: boolean
    can_manage_groups: boolean
    can_read_roster: boolean
    can_view_temporary_enrollments: boolean
    manage_grading_schemes: boolean
    set_grading_scheme: boolean
    manage_rubrics: boolean
    manage_outcomes: boolean
    logging:
      | false
      | {
          authentication: boolean
          grade_change: boolean
          course: boolean
          mutation: boolean
        }
    restore_course: boolean
    view_messages: boolean
    can_view_institutional_tags: boolean
    can_create_institutional_tags: boolean
    can_edit_institutional_tags: boolean
  }
  BOUNCED_EMAILS_ADMIN_TOOL: boolean
}

/**
 * From AccountsController#sis_import
 */
export interface EnvAccountsSisImport {
  SHOW_SITE_ADMIN_CONFIRMATION: boolean
  INSTITUTIONAL_TAGS_ENABLED: boolean
}
