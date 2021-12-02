/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

// Returns a Promise that resolves when an element with the specified
// id appears in the DOM. The Promise resolves to the actual DOM element
// that is found. The Promise is rejected if the timeout period is reached
// before it appears.
//
// Uses requestAnimationFrame instead of MutationObserver because we would have
// to recursively observe the entire document tree which can make MutationObserver
// inefficient; by contrast, getElementById is very fast.

export default function awaitElement(id: string, timeout: number = 5000): Promise<HTMLElement> {
  return new Promise((resolve, reject) => {
    let raf: number | null = null

    const timer = setTimeout(() => {
      if (raf !== null) cancelAnimationFrame(raf)
      reject(new Error('Timeout waiting for element to appear'))
    }, timeout)

    function checkId() {
      const elt = document.getElementById(id)
      if (elt) {
        clearTimeout(timer)
        resolve(elt)
      } else raf = requestAnimationFrame(checkId)
    }
    checkId()
  })
}
