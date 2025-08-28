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

import {PropsWithChildren, useRef} from 'react'
import {useNode} from '@craftjs/core'
import {AddButton} from '../../../AddBlock/AddButton'
import {useBlockContentEditorContext} from '../../../BlockContentEditorContext'
import {useOpenSettingsTray} from '../../../hooks/useOpenSettingsTray'
import {useDeleteNode} from '../../../hooks/useDeleteNode'
import {useDuplicateNode} from '../../../hooks/useDuplicateNode'
import {useMoveBlock} from '../../../hooks/useMoveBlock'
import {BaseBlockLayout} from '../layout/BaseBlockLayout'
import {useSetEditMode} from '../useSetEditMode'
import {CopyButton} from './CopyButton'
import {EditButton} from './EditButton'
import {RemoveButton} from './RemoveButton'
import {ApplyButton} from './ApplyButton'
import {MoveButton} from './MoveButton'
import {BackgroundColorApplier} from './BackgroundColorApplier'
import {Flex} from '@instructure/ui-flex'

const InsertButton = () => {
  const {addBlockModal} = useBlockContentEditorContext()
  const {id} = useNode()
  return <AddButton onClicked={() => addBlockModal.open(id)} />
}

const DeleteButton = () => {
  const deleteNode = useDeleteNode()
  return <RemoveButton onClicked={deleteNode} />
}

const DuplicateButton = () => {
  const duplicateNode = useDuplicateNode()
  return <CopyButton onClicked={duplicateNode} />
}

const EditSettingsButton = () => {
  const {openSettingsTray} = useOpenSettingsTray()

  return <EditButton onClicked={openSettingsTray} />
}

const MoveBlockButton = () => {
  const {canMoveUp, canMoveDown, moveToTop, moveUp, moveToBottom, moveDown} = useMoveBlock()

  return (
    <MoveButton
      canMoveUp={canMoveUp}
      canMoveDown={canMoveDown}
      onMoveUp={moveUp}
      onMoveDown={moveDown}
      onMoveToTop={moveToTop}
      onMoveToBottom={moveToBottom}
    />
  )
}

export const BaseBlockEditWrapper = (
  props: PropsWithChildren<{
    title: string
    setIsEditMode: (isEditMode: boolean) => void
    isEditMode: boolean
    backgroundColor?: string
  }>,
) => {
  const ref = useRef<HTMLDivElement>(null)
  useSetEditMode(ref, props.setIsEditMode)

  return (
    <BackgroundColorApplier backgroundColor={props.backgroundColor || 'white'}>
      <BaseBlockLayout
        ref={ref}
        title={props.title}
        addButton={<InsertButton />}
        actionButtons={
          props.isEditMode
            ? [<ApplyButton key="action-save-button" onClick={() => props.setIsEditMode(false)} />]
            : []
        }
        menu={
          <Flex gap="mediumSmall">
            <DuplicateButton key="menu-duplicate-button" />
            <EditSettingsButton key="menu-edit-settings-button" />
            <DeleteButton key="menu-delete-button" />
            <MoveBlockButton key="menu-move-block-button" />
          </Flex>
        }
      >
        {props.children}
      </BaseBlockLayout>
    </BackgroundColorApplier>
  )
}
