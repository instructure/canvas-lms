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

import {type Node} from '@craftjs/core'

export function getNodeIndex(node: Node, query: any) {
  const parentId = node.data.parent || 'ROOT'
  const siblings = query.node(parentId).descendants()
  const myIndex = siblings.indexOf(node.id)
  return myIndex
}

export type SectionLocation = 'top' | 'bottom' | 'middle' | 'alone'
export function getSectionLocation(node: Node, query: any): SectionLocation {
  const sections = query.node('ROOT').descendants()
  if (sections.length === 1) {
    return 'alone'
  }
  const index = getNodeIndex(node, query)
  if (index === 0) {
    return 'top'
  }
  if (index === sections.length - 1) {
    return 'bottom'
  }
  return 'middle'
}
