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

import {PropsWithChildren} from 'react'
import {useNode} from '@craftjs/core'
import {AddButton} from '../../../AddBlock/AddButton'
import {useBlockContentEditorContext} from '../../../BlockContentEditorContext'
import {useOpenSettingsTray} from '../../../hooks/useOpenSettingsTray'
import {useDeleteNode} from '../../../hooks/useDeleteNode'
import {useDuplicateNode} from '../../../hooks/useDuplicateNode'
import {useMoveBlock} from '../../../hooks/useMoveBlock'
import {useIsEditingBlock} from '../../../hooks/useIsEditingBlock'
import {BaseBlockLayout} from '../layout/BaseBlockLayout'
import {CopyButton} from './CopyButton'
import {SettingsButton} from './SettingsButton'
import {RemoveButton} from './RemoveButton'
import {MoveButton} from './MoveButton'
import {BackgroundColorApplier} from './BackgroundColorApplier'
import {Flex} from '@instructure/ui-flex'
import {A11yDoneEditingButton} from './A11yDoneEditingButton'
import {A11yEditButton} from './A11yEditButton'
import {useInstUIRef} from '../useInstUIRef'

const InsertButton = () => {
  const {addBlockModal} = useBlockContentEditorContext()
  const {id} = useNode()
  return <AddButton onClicked={() => addBlockModal.open(id)} />
}

const DeleteButton = ({title}: {title: string}) => {
  const deleteNode = useDeleteNode()
  return <RemoveButton onClicked={deleteNode} title={title} />
}

const DuplicateButton = ({title}: {title: string}) => {
  const duplicateNode = useDuplicateNode()
  return <CopyButton onClicked={duplicateNode} title={title} />
}

const EditSettingsButton = ({title}: {title: string}) => {
  const {openSettingsTray} = useOpenSettingsTray()

  return <SettingsButton onClicked={openSettingsTray} title={title} />
}

const MoveBlockButton = ({title}: {title: string}) => {
  const {canMoveUp, canMoveDown, moveToTop, moveUp, moveToBottom, moveDown} = useMoveBlock()

  return (
    <MoveButton
      canMoveUp={canMoveUp}
      canMoveDown={canMoveDown}
      onMoveUp={moveUp}
      onMoveDown={moveDown}
      onMoveToTop={moveToTop}
      onMoveToBottom={moveToBottom}
      title={title}
    />
  )
}

export const BaseBlockEditWrapper = (
  props: PropsWithChildren<{
    title: string
    backgroundColor?: string
  }>,
) => {
  const {id, customTitle, includeBlockTitle} = useNode(node => ({
    id: node.id,
    customTitle: node.data.props?.title,
    includeBlockTitle: node.data.props?.includeBlockTitle,
  }))
  const {editingBlock} = useBlockContentEditorContext()
  const {isEditingBlock, isEditedViaEditButton, setIsEditedViaEditButton} = useIsEditingBlock()
  const [editButtonRef, setEditButtonRef] = useInstUIRef<HTMLButtonElement>()

  const blockTitle =
    includeBlockTitle !== false && typeof customTitle === 'string' && customTitle.trim() !== ''
      ? customTitle
      : props.title

  const handleSave = () => {
    editingBlock.setId(null)
    setIsEditedViaEditButton(false)
    setTimeout(() => editButtonRef?.current?.focus(), 0)
  }

  const handleEdit = () => {
    setIsEditedViaEditButton(true)
    editingBlock.setId(id)
  }

  return (
    <BackgroundColorApplier backgroundColor={props.backgroundColor || 'white'}>
      <BaseBlockLayout
        nodeId={id}
        title={props.title}
        addButton={<InsertButton />}
        bottomA11yActionMenu={
          isEditingBlock && (
            <A11yDoneEditingButton
              onUserAction={handleSave}
              isFullyVisible={isEditedViaEditButton}
            />
          )
        }
        menu={
          <Flex gap="mediumSmall">
            <DuplicateButton key="menu-duplicate-button" title={blockTitle} />
            <EditSettingsButton key="menu-edit-settings-button" title={blockTitle} />
            <DeleteButton key="menu-delete-button" title={blockTitle} />
            <MoveBlockButton key="menu-move-block-button" title={blockTitle} />
          </Flex>
        }
        topA11yActionMenu={
          !isEditingBlock ? (
            <A11yEditButton onUserAction={handleEdit} elementRef={setEditButtonRef} />
          ) : (
            <A11yDoneEditingButton onUserAction={handleSave} isFullyVisible={false} />
          )
        }
      >
        {props.children}
      </BaseBlockLayout>
    </BackgroundColorApplier>
  )
}
