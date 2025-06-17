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

import {PropsWithChildren, useRef, useState} from 'react'
import {BaseBlockLayout} from './BaseBlockLayout'
import {BlockContext} from './BaseBlockContext'
import {useSetEditMode} from './useSetEditMode'
import {RemoveButton} from './RemoveButton'
import {AddButton} from '../../AddBlock/AddButton'
import {useDeleteNode} from '../../hooks/useDeleteNode'
import {useDuplicateNode} from '../../hooks/useDuplicateNode'
import {useNode} from '@craftjs/core'
import {usePageEditorContext} from '../../PageEditorContext'
import {ApplyButton} from './ApplyButton'
import {CopyButton} from './CopyButton'

const InsertButton = () => {
  const {addBlockModal} = usePageEditorContext()
  const {id} = useNode()
  return <AddButton onClicked={() => addBlockModal.open(id)} />
}

const DeleteButton = () => {
  const deleteNode = useDeleteNode()

  return <RemoveButton onClicked={deleteNode} />
}

const SaveButton = (props: {
  onClick: () => void
}) => {
  return <ApplyButton onClick={props.onClick} />
}

const DuplicateButton = () => {
  const duplicateNode = useDuplicateNode()

  return <CopyButton onClicked={duplicateNode} />
}

export const BaseBlock = (
  props: PropsWithChildren<{
    title: string
  }>,
) => {
  const [isEditMode, setIsEditMode] = useState(false)
  const ref = useRef<HTMLDivElement>(null)
  useSetEditMode(ref, setIsEditMode)

  return (
    <BlockContext.Provider value={{isEditMode}}>
      <BaseBlockLayout
        ref={ref}
        title={props.title}
        addButton={<InsertButton />}
        actionButtons={
          isEditMode
            ? [<SaveButton key="action-save-btn" onClick={() => setIsEditMode(false)} />]
            : []
        }
        menu={[
          <DuplicateButton key="menu-duplicate-btn" />,
          <DeleteButton key="menu-delete-btn" />,
        ]}
      >
        {props.children}
      </BaseBlockLayout>
    </BlockContext.Provider>
  )
}
