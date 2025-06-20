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
import {usePageEditorContext} from '../PageEditorContext'
import {AddBlockModal} from './AddBlockModal'
import {useAddNode} from '../hooks/useAddNode'

export const AddBlockModalRenderer = (props: {}) => {
  const {addBlockModal} = usePageEditorContext()
  const addNode = useAddNode()
  const onAddBlock = (block: ReactElement) => {
    addNode(block, addBlockModal.insertAfterNodeId)
  }

  return (
    <AddBlockModal
      open={addBlockModal.isOpen}
      onDismiss={addBlockModal.close}
      onAddBlock={onAddBlock}
    />
  )
}
