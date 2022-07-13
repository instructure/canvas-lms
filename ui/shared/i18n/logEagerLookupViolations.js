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

import {captureException} from '@sentry/browser'

let translationsAvailable = false

class EagerLookupViolationError extends Error {
  constructor(phrase) {
    super()
    this.message = `eager lookup for phrase "${phrase}"`
    this.name = 'EagerLookupViolationError'
  }
}

const trackReadiness = ({detail}) => {
  if (detail === 'capabilities') {
    translationsAvailable = true
    window.removeEventListener('canvasReadyStateChange', trackReadiness)
  }
}

window.addEventListener('canvasReadyStateChange', trackReadiness)

export default function (f) {
  return function () {
    if (!translationsAvailable) {
      const phrase = [].slice.call(arguments, 0, 1)
      const error = new EagerLookupViolationError(phrase)

      // don't block
      window.setTimeout(() => {
        captureException(error)
      }, 0)
    }

    return f.apply(this, arguments)
  }
}
