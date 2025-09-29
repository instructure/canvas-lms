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
import {useInstUIRef} from '../../../hooks/useInstUIRef'
import {useAddBlockModal} from '../../../hooks/useAddBlockModal'
import {useSettingsTray} from '../../../hooks/useSettingsTray'
import {useEditingBlock} from '../../../hooks/useEditingBlock'

const InsertButton = () => {
  const {id} = useNode()
  const {open} = useAddBlockModal()
  return <AddButton onClicked={() => open(id)} />
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
  const {id} = useNode()
  const {open} = useSettingsTray()
  return <SettingsButton onClicked={() => open(id)} title={title} />
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
  const {setId} = useEditingBlock()
  const {isEditing, isEditingViaEditButton: isEditingByKeyboard} = useIsEditingBlock()
  const [editButtonRef, setEditButtonRef] = useInstUIRef<HTMLButtonElement>()

  const blockTitle =
    includeBlockTitle !== false && typeof customTitle === 'string' && customTitle.trim() !== ''
      ? customTitle
      : props.title

  const handleSave = () => {
    setId(null)
    setTimeout(() => editButtonRef?.current?.focus(), 0)
  }

  const handleEditByKeyboard = () => {
    setId(id, true)
  }

  return (
    <BackgroundColorApplier backgroundColor={props.backgroundColor || 'white'}>
      <BaseBlockLayout
        nodeId={id}
        title={props.title}
        addButton={<InsertButton />}
        bottomA11yActionMenu={
          isEditing && (
            <A11yDoneEditingButton onUserAction={handleSave} isFullyVisible={isEditingByKeyboard} />
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
          !isEditing ? (
            <A11yEditButton onUserAction={handleEditByKeyboard} elementRef={setEditButtonRef} />
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
