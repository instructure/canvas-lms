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
import {type NodeTree, type Node, type SerializedNode} from '@craftjs/core'
import {getRandomId} from '@craftjs/utils'
import {type TemplateNodeTree} from '../types'

export type NodePair = [string, Node]
export type SerializedNodePair = [string, SerializedNode]

export const getCloneTree = (tree: NodeTree, query: any): NodeTree => {
  const newNodes: Record<string, Node> = {}
  const changeNodeId = (node: Node, newParentId?: string) => {
    const newNodeId = getRandomId()
    const childNodes = node.data.nodes.map(childId => changeNodeId(tree.nodes[childId], newNodeId))
    const linkedNodes = Object.keys(node.data.linkedNodes).reduce((acc, id) => {
      const newLinkedNodeId = changeNodeId(tree.nodes[node.data.linkedNodes[id]], newNodeId)
      return {
        ...acc,
        [id]: newLinkedNodeId,
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
    const freshNode = query.parseFreshNode(tmpNode).toNode()
    newNodes[newNodeId] = freshNode
    return newNodeId
  }

  const rootNodeId = changeNodeId(tree.nodes[tree.rootNodeId])
  return {
    rootNodeId,
    nodes: newNodes,
  }
}

export const getNodeTemplate = (id: string, name: string, query: any): TemplateNodeTree => {
  const tree = query.node(id).toNodeTree()
  const nodePairs: SerializedNodePair[] = Object.keys(tree.nodes).map(nid => [
    nid,
    query.node(nid).toSerializedNode(),
  ])
  const saveData: TemplateNodeTree = {
    rootNodeId: tree.rootNodeId,
    nodes: Object.fromEntries(nodePairs),
  }
  const rootNode = saveData.nodes[saveData.rootNodeId]
  if (rootNode.custom) {
    // nodes returned from toSerializedNode are still made of invariants
    // copy to undo that
    rootNode.custom = {...rootNode.custom}
  } else {
    rootNode.custom = {}
  }
  rootNode.custom.displayName = name
  delete rootNode.props.isColumn

  return saveData
}

export const createFromTemplate = (template: TemplateNodeTree, query: any): NodeTree => {
  const newNodes = template.nodes
  const nodePairs: NodePair[] = Object.keys(newNodes).map(id => {
    const nodeId = id
    return [
      nodeId,
      query.parseSerializedNode(newNodes[id]).toNode((node: Node) => (node.id = nodeId)),
    ]
  })
  const tree: NodeTree = {
    rootNodeId: template.rootNodeId,
    nodes: Object.fromEntries(nodePairs),
  }
  const newTree = getCloneTree(tree, query)
  return newTree
}
