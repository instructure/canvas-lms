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

import {ReactElement} from 'react'
import {AddBlockModal} from './AddBlockModal'
import {useAddNode} from '../hooks/useAddNode'
import {useAddBlockModal} from '../hooks/useAddBlockModal'
import {useAppSelector} from '../store'

export const AddBlockModalRenderer = () => {
  const {isOpen, insertAfterNodeId} = useAppSelector(state => state.addBlockModal)
  const {close} = useAddBlockModal()
  const addNode = useAddNode()
  const onAddBlock = (block: ReactElement) => {
    addNode(block, insertAfterNodeId)
  }

  return <AddBlockModal open={isOpen} onDismiss={close} onAddBlock={onAddBlock} />
}
