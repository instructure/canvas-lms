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

// This adds a new property to the DOM Node prototype that returns the visible
// text content of the node. node.visibleTextContent will work just like node.textContent
// but will omit any non-displayed text nodes (e.g. text nodes inside hidden elements
// such as screenreader content.)

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

declare global {
  interface Node {
    visibleTextContent: string
  }
}

export function up(): void {
  if (
    typeof Object.getOwnPropertyDescriptor(Node.prototype, 'visibleTextContent')?.get ===
    'undefined'
  ) {
    Object.defineProperty(Node.prototype, 'visibleTextContent', {
      get() {
        return getVisibleTextContent(this)
      },
      enumerable: true,
    })
  }
}
