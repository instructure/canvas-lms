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

import {assignLocation} from '@canvas/util/globalUtils'
import type {FormMessage} from '@instructure/ui-form-field'

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
  text ? [{type: 'newError', text}] : []

/**
 * Handle possible redirects after successful registration
 * @param data Response data containing potential destination or course info
 */
export const handleRegistrationRedirect = (data: any): void => {
  if (data.destination) {
    assignLocation(data.destination)
  } else if (data.course) {
    assignLocation(`/courses/${data.course.course.id}?registration_success=1`)
  } else {
    assignLocation('/?registration_success=1')
  }
}
