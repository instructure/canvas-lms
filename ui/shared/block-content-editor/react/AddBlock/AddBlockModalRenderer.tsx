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
import {useScope as createI18nScope} from '@canvas/i18n'
import {showScreenReaderAlert} from '../utilities/accessibility'
import {useFocusManagement} from '../hooks/useFocusManagement'

const I18n = createI18nScope('block_content_editor')

export const AddBlockModalRenderer = () => {
  const {isOpen, insertAfterNodeId} = useAppSelector(state => state.addBlockModal)
  const {close} = useAddBlockModal()
  const addNode = useAddNode()
  const {focusCopyButton} = useFocusManagement()

  const onAddBlock = (block: ReactElement) => {
    const addedNode = addNode(block, insertAfterNodeId)
    const alertMessage = I18n.t('Block added: %{blockType}', {
      blockType: addedNode.data.displayName,
    })
    showScreenReaderAlert(alertMessage)
    focusCopyButton(addedNode.id)
  }

  return <AddBlockModal open={isOpen} onDismiss={close} onAddBlock={onAddBlock} />
}
