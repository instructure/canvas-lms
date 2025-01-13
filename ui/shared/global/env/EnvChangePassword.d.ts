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

type PasswordPolicyAndPseudonym = {
  policy: {maximum_login_attempts: string; minimum_character_length: string}
  pseudonym: {unique_id: string; account_display_name: string}
}

export interface EnvChangePassword {
  PASSWORD_POLICY: PasswordPolicyAndPseudonym
  PASSWORD_POLICIES: {[pseudonymId: string]: PasswordPolicyAndPseudonym}
  CC: {
    confirmation_code: string
    path: string
  }
  PSEUDONYM: {
    id: string
    user_name: string
  }
}
