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

export interface PasswordPolicy {
  require_number_characters: boolean
  require_symbol_characters: boolean
  allow_login_suspension: boolean
  maximum_login_attempts?: number
  minimum_character_length?: number
  common_passwords_attachment_id?: number | null
  common_passwords_folder_id?: number | null
}

export interface PasswordSettings {
  password_policy: PasswordPolicy
}

interface PasswordPolicyApiResponse {
  require_number_characters: string
  require_symbol_characters: string
  allow_login_suspension: string
  maximum_login_attempts?: number
  minimum_character_length?: number
  common_passwords_attachment_id?: number | null
  common_passwords_folder_id?: number | null
}

export interface PasswordSettingsResponse {
  password_policy: PasswordPolicyApiResponse
}
