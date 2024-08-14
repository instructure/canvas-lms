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

// This is a polyfill for Node.prototype.innerText, which is not supported in JSDOM.
// It will run at boot time if the browser does not support innerText,
// which should never happen for a "real" browser but definitely willl
// happen in Jest tests using JSDOM.
//
// Written so that other DOM polyfills can be easily added here as needed.

// exported for tests only
export const getVisibleTextContent = (element: Node): string =>
  Array.from(element.childNodes)
    .filter(
      node =>
        node.nodeType === Node.TEXT_NODE ||
        (node instanceof HTMLElement && getComputedStyle(node).display !== 'none')
    )
    .map(node => node.textContent?.trim())
    // remove empty strings using Boolean operation
    .filter(Boolean)
    .join(' ')
    .trim()

function polyfillInnerText(): void {
  // be careful that this is idempotent
  if ('innerText' in document.body) return
  Object.defineProperty(Node.prototype, 'innerText', {
    get() {
      return getVisibleTextContent(this)
    },
    enumerable: true,
  })
}

export function up(): void {
  polyfillInnerText()
}
