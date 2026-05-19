/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

export interface EnvProfiles {
  register_cc_tabs: Array<'email' | 'sms' | 'slack'>
  is_default_account: boolean
  google_drive_oauth_url: string
  PERMISSIONS: {
    can_update_tokens: boolean
    can_view_user_generated_access_tokens: boolean
    can_manage_dsr_requests: boolean
    can_read_sis: boolean
    can_add_temporary_enrollments: boolean
    can_edit_temporary_enrollments: boolean
    can_delete_temporary_enrollments: boolean
    can_add_teacher: boolean
    can_add_ta: boolean
    can_add_student: boolean
    can_add_observer: boolean
    can_add_designer: boolean
  }
  USER_ID: string
  CONTEXT_USER_DISPLAY_NAME: string
}
