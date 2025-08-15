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

import {useNode} from '@craftjs/core'
import {useGetRootNode} from './useGetRootNode'
import {useGetBlocksCount} from './useGetBlocksCount'

export const useMoveBlock = () => {
  const {id} = useNode()
  const {rootNode} = useGetRootNode()
  const {blocksCount} = useGetBlocksCount()

  const nodeIndex = rootNode.data.nodes.indexOf(id)

  return {
    canMoveUp: nodeIndex > 0,
    canMoveDown: nodeIndex < blocksCount - 1,
  }
}
