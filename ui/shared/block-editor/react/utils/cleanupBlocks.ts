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

import {type NodeTreeNodes} from '../types'

// We don't want the expanded state to be saved with the block data
export const closeExpandedBlocks = (query: any): NodeTreeNodes => {
  const nodes = JSON.parse(query.serialize())
  Object.keys(nodes).forEach(k => {
    const node = nodes[k]
    delete node.custom?.isExpanded
  })
  return nodes
}

// NOTE: this is not being used, but it is a good example
// of how to iterate over the json. Might be a good foundation
// for copying a block and changing its IDs (since the current
// getCloneTree() function is broken)
function deleteNode(blocks: any, nodeid: string) {
  const node = blocks[nodeid]
  if (node.nodes) {
    for (const child of node.nodes) {
      deleteNode(blocks, child)
    }
  }
  delete blocks[nodeid]
}

export const cleanupBlocks = (json: string) => {
  try {
    const blocks = JSON.parse(json)
    const blockIds = Object.keys(blocks)
    for (const blockid of blockIds) {
      const block = blocks[blockid]
      if (block?.hidden) {
        const parent = block.parent
        const parentBlock = blocks[parent]
        if (parentBlock) {
          const linkedBlockKey = Object.keys(parentBlock.linkedNodes).find(
            key => parentBlock.linkedNodes[key] === blockid,
          )
          if (linkedBlockKey) {
            delete parentBlock.linkedNodes[linkedBlockKey]
            deleteNode(blocks, blockid)
          }
        }
      }
    }
    return JSON.stringify(blocks)
  } catch (e) {
    return json
  }
}
