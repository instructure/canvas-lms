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

import type {FormMessage} from '@instructure/ui-form-field'
import type {PasswordPolicy} from '../types'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('new_login')

/**
 * Regular expression to validate email addresses
 * Ensures the email format includes a local part, an "@" symbol, and a domain.
 * Examples of valid emails:
 * - example@domain.com
 * - user.name@sub.domain.org
 * Examples of invalid emails:
 * - example@domain (missing TLD)
 * - @domain.com (missing local part)
 */
export const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

/**
 * Create a FormMessage array with a single error message
 * @param text Error message text
 * @returns FormMessage[]
 */
export const createErrorMessage = (text: string): FormMessage[] =>
  text ? [{type: 'error', text}] : []

/**
 * Validate a password based on a given password policy
 * @param password Password string to validate
 * @param policy Password policy to validate against
 * @returns Error message string if validation fails, or null if valid
 */
export const validatePassword = (
  password: string | undefined,
  policy: PasswordPolicy
): string | null => {
  if (!password) return null

  const {minimumCharacterLength = 0, requireNumberCharacters, requireSymbolCharacters} = policy

  if (password.length < minimumCharacterLength) {
    return I18n.t(`Password must be at least %{minimumCharacterLength} characters long.`, {
      minimumCharacterLength,
    })
  }

  if (requireNumberCharacters && !/\d/.test(password)) {
    return I18n.t('Password must include at least one numeric character.')
  }

  if (requireSymbolCharacters && !/[!@#$%^&*(),.?":{}|<>]/.test(password)) {
    return I18n.t('Password must include at least one special character.')
  }

  return null
}

/**
 * Handle possible redirects after successful registration
 * @param data Response data containing potential destination or course info
 */
export const handleRegistrationRedirect = (data: any): void => {
  if (data.destination) {
    window.location.replace(data.destination)
  } else if (data.course) {
    window.location.replace(`/courses/${data.course.course.id}?registration_success=1`)
  } else {
    window.location.replace('/?registration_success=1')
  }
}
