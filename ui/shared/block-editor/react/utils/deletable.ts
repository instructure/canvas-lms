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

// Used as part of the isDeletable logic.
// Return false if the Node identified my nodeId is the last child
// of its parent.
// This is true of all sections (so this is called in RenderNode to
// save you from having to add it to each section) and some blocks

export const isNthChild = (nodeId: string, query: any, n: number) => {
  const target = query.node(nodeId).get()
  if (target.data.parent) {
    const siblings = query.node(target.data.parent).descendants()
    return siblings.length === n
  }
  return false
}

export const isLastChild = (nodeId: string, query: any) => {
  return isNthChild(nodeId, query, 1)
}
