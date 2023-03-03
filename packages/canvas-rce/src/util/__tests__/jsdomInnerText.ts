/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

/**
 * Implementation of innerText that works similar to browsers, but works with jsdom in tests.
 *
 * From https://github.com/jsdom/jsdom/issues/1245#issuecomment-1243809196
 *
 * @param node
 */
export function jsdomInnerText(node: Node): string {
  return Array.from(node.childNodes)
    .map(child => {
      switch (child.nodeType) {
        case Node.TEXT_NODE:
          return child.textContent
        case Node.ELEMENT_NODE:
          return jsdomInnerText(child)
        default:
          return ''
      }
    })
    .join('\n')
}
