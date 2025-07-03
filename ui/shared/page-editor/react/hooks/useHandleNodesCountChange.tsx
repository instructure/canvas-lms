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

import {useCallback} from 'react'
import {useGetRootNode} from './useGetRootNode'
import {usePageEditorContext} from '../PageEditorContext'

export const useHandleNodesCountChange = () => {
  const getRootNode = useGetRootNode()
  const {addBlock} = usePageEditorContext()

  const handleNodesCountChange = useCallback(() => {
    const rootNode = getRootNode()
    const rootNodesCount = rootNode ? rootNode.data.nodes.length : 0
    addBlock.setShouldShow(rootNodesCount === 0)
  }, [getRootNode, addBlock])

  return handleNodesCountChange
}
