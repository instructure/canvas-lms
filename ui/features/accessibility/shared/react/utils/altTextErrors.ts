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

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('accessibility_checker')

export const altTextGenerationErrorMessage = (statusCode: number): string => {
  switch (statusCode) {
    case 403:
      return I18n.t('You do not have permission to access this attachment.')
    case 404:
      return I18n.t('Attachment not found.')
    case 413:
      return I18n.t('The file exceeds the maximum allowed size for AI processing.')
    case 415:
      return I18n.t('This file type is not supported for AI processing.')
    case 429:
      return I18n.t(
        'You have exceeded your daily limit for alt text generation. (You can generate alt text for 300 images per day.) Please try again after a day, or enter alt text manually.',
      )
    default:
      return I18n.t(
        'There was an error generating alt text. Please try again, or enter it manually.',
      )
  }
}
