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

// code copied from https://github.com/prevwong/craft.js/issues/209#issuecomment-795221484
// but with a couple modifications

import {type Node} from '@craftjs/core'
import {uid} from '@instructure/uid'

export const getCloneTree = (idToClone: string, query: any) => {
  const tree = query.node(idToClone).toNodeTree()
  const newNodes: Record<string, Node> = {}

  const changeNodeId = (node: Node, newParentId?: string) => {
    const newNodeId = uid('node', 2)
    const childNodes = node.data.nodes.map(childId => changeNodeId(tree.nodes[childId], newNodeId))
    const linkedNodes = Object.keys(node.data.linkedNodes).reduce((accum, id) => {
      const linkedNodeId = changeNodeId(tree.nodes[node.data.linkedNodes[id]], newNodeId)
      return {
        ...accum,
        [id]: linkedNodeId,
      }
    }, {})

    const tmpNode = {
      ...node,
      id: newNodeId,
      data: {
        ...node.data,
        parent: newParentId || node.data.parent,
        nodes: childNodes,
        linkedNodes,
      },
    }
    const freshnode = query.parseFreshNode(tmpNode).toNode()
    newNodes[newNodeId] = freshnode
    return newNodeId
  }

  const rootNodeId = changeNodeId(tree.nodes[tree.rootNodeId])
  return {
    rootNodeId,
    nodes: newNodes,
  }
}
