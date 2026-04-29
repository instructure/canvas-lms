/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {useEditor, Node} from '@craftjs/core'
import {ReactElement} from 'react'
import {useGetRootNode} from './useGetRootNode'

export const useAddNode = () => {
  const {query, actions} = useEditor()
  const {rootNode} = useGetRootNode()

  const getIndex = (afterNodeId?: string) => {
    if (!afterNodeId) {
      return 0
    }
    const siblings = rootNode.data.nodes
    return siblings.indexOf(afterNodeId) + 1
  }

  const addNode = (element: ReactElement, afterNodeId?: string): Node => {
    const nodeTree = query.parseReactElement(element).toNodeTree()
    const index = getIndex(afterNodeId)
    actions.addNodeTree(nodeTree, rootNode.id, index)
    return query.node(nodeTree.rootNodeId).get()
  }
  return addNode
}
