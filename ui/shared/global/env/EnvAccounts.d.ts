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

export type EnvAccounts = Partial<EnvAccountsAdminTools>

/**
 * From AccountsController#admin_tools
 */
export interface EnvAccountsAdminTools {
  ROOT_ACCOUNT_NAME: string
  ACCOUNT_ID: string
  PERMISSIONS: {
    can_allow_course_admin_actions: boolean
    can_create_enrollments: boolean
    can_create_users: boolean
    can_manage_admin_users: boolean
    can_manage_groups: boolean
    can_read_roster: boolean
    can_view_temporary_enrollments: boolean
    manage_grading_schemes: boolean
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
  }
  bounced_emails_admin_tool: boolean
}
