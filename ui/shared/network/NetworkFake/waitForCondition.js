/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

const originals = {
  clearInterval: window.clearInterval,
  clearTimeout: window.clearTimeout,
  setInterval: window.setInterval,
  setTimeout: window.setTimeout
}

export default function waitForCondition(conditionFn, timeout = 500) {
  return new Promise((resolve, reject) => {
    let timeoutId

    const interval = 10 // ms
    const intervalFn = () => {
      const result = conditionFn()
      if (result) {
        originals.clearInterval.call(window, intervalId)
        originals.clearTimeout.call(window, timeoutId)
        resolve(result)
      }
    }
    const intervalId = originals.setInterval.call(window, intervalFn, interval)

    const timeoutFn = () => {
      originals.clearInterval.call(window, intervalId)
      reject(new Error('Timeout waiting for condition'))
    }
    timeoutId = originals.setTimeout.call(window, timeoutFn, timeout)
  })
}
