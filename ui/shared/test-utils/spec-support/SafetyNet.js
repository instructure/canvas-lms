/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

/* eslint-disable no-console */

import QUnit from 'qunitjs'

export default class SafetyNet {
  setup() {
    /*
     * `window.onerror` is used because QUnit expects it to be used for
     * handling global errors.
     */
    window.onerror = this.onError
  }

  teardown() {
    window.onerror = null
  }

  onError(message, filePath, lineNumber, columnNumber, error) {
    console.error('Uncaught Error!')
    console.error(error.stack)

    function callback() {
      QUnit.pushFailure(error, `${filePath}:${lineNumber}`)
    }

    if (QUnit.config.current) {
      callback()
    } else {
      QUnit.test('global error', QUnit.extend(callback, {validTest: true}))
    }

    /*
     * Prevent default behavior
     */
    return true
  }
}
/* eslint-enable no-console */
