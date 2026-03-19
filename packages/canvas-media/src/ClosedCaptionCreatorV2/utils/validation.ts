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

import formatMessage from '../../format-message'
import {CC_FILE_MAX_BYTES} from '../../shared/constants'
import type {ValidationResult} from '../types'

/**
 * Validates a caption file for size and type
 * @param file - The file to validate
 * @returns ValidationResult with valid flag and optional error message
 */
export function validateCaptionFile(file: File): ValidationResult {
  // Check file size
  if (file.size > CC_FILE_MAX_BYTES) {
    return {
      valid: false,
      error: formatMessage('The selected file exceeds the {maxSize} Byte limit', {
        maxSize: CC_FILE_MAX_BYTES,
      }),
    }
  }

  // Check file type/extension
  const validExtensions = ['.vtt', '.srt']
  const fileName = file.name.toLowerCase()
  const hasValidExtension = validExtensions.some(ext => fileName.endsWith(ext))

  if (!hasValidExtension) {
    return {
      valid: false,
      error: formatMessage('Please select a .vtt or .srt file'),
    }
  }

  return {valid: true}
}
