/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import formatMessage from '../format-message'

/*
 * builds an a displayable error based on errorContext and error
 *
 * @param {Object} errorContext - An object providing context for the error (for example,
 *   an error response from a request)
 * @param {Error} - The actual Error being processed
 *
 * @returns { Object } Displayable error - An object with "text" and "variant" keys
 */
export default function buildError(errorContext, error) {
  return getErrorClass(errorContext, error).build(error)
}

function getErrorClass(errorContext, error) {
  const errors = [QuotaError, CaptionSizeError, CaptionCreationError, DefaultError]

  // Find the first error class that matches the given context and error.
  // Defaults to DefaultError
  return errors.find(ErrorClass => ErrorClass.isMatch(errorContext, error))
}

class QuotaError {
  static isMatch(errorContext) {
    return errorContext?.message === 'file size exceeds quota'
  }

  static build(_error) {
    return {
      text: formatMessage('File storage quota exceeded'),
      variant: 'error',
    }
  }
}

class CaptionSizeError {
  static isMatch(_errorContext, error) {
    return error?.name === 'FileSizeError'
  }

  static build(error) {
    return {
      text: formatMessage('Closed caption file must be less than {maxKb} kb', {
        maxKb: error.maxBytes / 1000, // bytes to kb
      }),
      variant: 'error',
    }
  }
}

class CaptionCreationError {
  static isMatch(errorContext) {
    return errorContext?.message === 'failed to save captions'
  }

  static build(_error) {
    return {
      text: formatMessage('loading closed captions/subtitles failed.'),
      variant: 'error',
    }
  }
}

class DefaultError {
  static isMatch() {
    // DefaultError comes last in the list an always matches
    return true
  }

  static build(_error) {
    return {
      text: formatMessage(
        'Something went wrong. Check your connection, reload the page, and try again.'
      ),
      variant: 'error',
    }
  }
}
