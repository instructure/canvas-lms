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

export const usePreviousBlock = () => {
  const {id} = useNode()
  const {rootNode} = useGetRootNode()

  const getPreviousBlockId = (): string | null => {
    const siblings = rootNode.data.nodes
    const currentIndex = siblings.indexOf(id)

    if (currentIndex > 0) {
      return siblings[currentIndex - 1]
    }

    return null
  }

  return {getPreviousBlockId}
}
