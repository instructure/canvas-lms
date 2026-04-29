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

import {useNode, useEditor} from '@craftjs/core'
import {useGetRootNode} from './useGetRootNode'
import {useGetBlocksCount} from './useGetBlocksCount'

export const useMoveBlock = () => {
  const {
    actions: {move},
  } = useEditor()
  const {id} = useNode()
  const {rootNode} = useGetRootNode()
  const {blocksCount} = useGetBlocksCount()
  const nodeIndex = rootNode.data.nodes.indexOf(id)

  const canMoveUp = nodeIndex > 0
  const canMoveDown = nodeIndex < blocksCount - 1

  const moveBlock = (position: number) => {
    // The built-in move action has ordering issues when moving within the same parent.
    // It marks the node for deletion first, then performs the insert, and finally
    // executes the actual delete in cleanup. This sequence disrupts index calculations
    // since the node still exists during insertion.
    move(id, rootNode.id, position)
  }

  const moveToTop = () => {
    if (!canMoveUp) return
    moveBlock(0)
  }

  const moveUp = () => {
    if (!canMoveUp) return
    moveBlock(nodeIndex - 1)
  }

  const moveToBottom = () => {
    if (!canMoveDown) return
    moveBlock(blocksCount)
  }

  const moveDown = () => {
    if (!canMoveDown) return
    moveBlock(nodeIndex + 2)
  }

  return {
    canMoveUp,
    canMoveDown,
    moveToTop,
    moveUp,
    moveToBottom,
    moveDown,
  }
}
