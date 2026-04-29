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
import {useScope as createI18nScope} from '@canvas/i18n'
import {AddButton} from '../../../AddBlock/AddButton'
import {useDeleteNode} from '../../../hooks/useDeleteNode'
import {useDuplicateNode} from '../../../hooks/useDuplicateNode'
import {useMoveBlock} from '../../../hooks/useMoveBlock'
import {useIsEditingBlock} from '../../../hooks/useIsEditingBlock'
import {useBlockTitle} from '../../../hooks/useBlockTitle'
import {showScreenReaderAlert} from '../../../utilities/accessibility'
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
import {useFocusManagement} from '../../../hooks/useFocusManagement'
import {useGetBlocksCount} from '../../../hooks/useGetBlocksCount'
import {usePreviousBlock} from '../../../hooks/usePreviousBlock'
import {useNextBlock} from '../../../hooks/useNextBlock'

const I18n = createI18nScope('block_content_editor')

const InsertButton = () => {
  const {id} = useNode()
  const {open} = useAddBlockModal()
  const {elementRef} = useFocusManagement({buttonType: 'insertButton', nodeId: id})
  return <AddButton onClicked={() => open(id)} elementRef={elementRef} />
}

const DeleteButton = ({title}: {title: string}) => {
  const deleteNode = useDeleteNode()
  const {blocksCount} = useGetBlocksCount()
  const {getPreviousBlockId} = usePreviousBlock()
  const {getNextBlockId} = useNextBlock()
  const {focusAddBlockButton, focusInsertButton, focusCopyButton} = useFocusManagement()

  const handleDelete = () => {
    const isLastBlock = blocksCount === 1
    const previousBlockId = getPreviousBlockId()
    const nextBlockId = getNextBlockId()
    const isFirstBlock = !previousBlockId

    deleteNode()
    const alertMessage = I18n.t('Block removed: %{blockType}', {blockType: title})
    showScreenReaderAlert(alertMessage)

    if (isLastBlock) {
      focusAddBlockButton()
    } else if (isFirstBlock && nextBlockId) {
      focusCopyButton(nextBlockId)
    } else if (previousBlockId) {
      focusInsertButton(previousBlockId)
    }
  }
  return <RemoveButton onClicked={handleDelete} title={title} />
}

const DuplicateButton = ({
  title,
  elementRef,
}: {
  title: string
  elementRef?: (element: Element | null) => void
}) => {
  const duplicateNode = useDuplicateNode()
  const handleDuplicate = () => {
    duplicateNode()
    const alertMessage = I18n.t('Block duplicated: %{blockType}', {blockType: title})
    showScreenReaderAlert(alertMessage)
  }
  return <CopyButton onClicked={handleDuplicate} title={title} elementRef={elementRef} />
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
  const {id} = useNode()
  const {setId} = useEditingBlock()
  const {isEditing, isEditingViaEditButton: isEditingByKeyboard} = useIsEditingBlock()
  const [editButtonRef, setEditButtonRef] = useInstUIRef<HTMLButtonElement>()
  const blockTitle = useBlockTitle()
  const {elementRef: copyButtonRef} = useFocusManagement({buttonType: 'copyButton', nodeId: id})

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
            <A11yDoneEditingButton
              onUserAction={handleSave}
              isFullyVisible={isEditingByKeyboard}
              title={blockTitle}
            />
          )
        }
        menu={
          <Flex gap="mediumSmall">
            <DuplicateButton
              key="menu-duplicate-button"
              title={blockTitle}
              elementRef={copyButtonRef}
            />
            <EditSettingsButton key="menu-edit-block-settings-button" title={blockTitle} />
            <DeleteButton key="menu-delete-button" title={blockTitle} />
            <MoveBlockButton key="menu-move-block-button" title={blockTitle} />
          </Flex>
        }
        topA11yActionMenu={
          !isEditing ? (
            <A11yEditButton
              onUserAction={handleEditByKeyboard}
              elementRef={setEditButtonRef}
              title={blockTitle}
            />
          ) : (
            <A11yDoneEditingButton
              onUserAction={handleSave}
              isFullyVisible={false}
              title={blockTitle}
            />
          )
        }
      >
        {props.children}
      </BaseBlockLayout>
    </BackgroundColorApplier>
  )
}
