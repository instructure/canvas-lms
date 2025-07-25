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
import {useDeleteNode} from '../../../hooks/useDeleteNode'
import {useDuplicateNode} from '../../../hooks/useDuplicateNode'
import {BaseBlockLayout} from '../layout/BaseBlockLayout'
import {useSetEditMode} from '../useSetEditMode'
import {CopyButton} from './CopyButton'
import {RemoveButton} from './RemoveButton'
import {ApplyButton} from './ApplyButton'

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

export const BaseBlockEditWrapper = (
  props: PropsWithChildren<{
    title: string
    setIsEditMode: (isEditMode: boolean) => void
    isEditMode: boolean
  }>,
) => {
  const ref = useRef<HTMLDivElement>(null)
  useSetEditMode(ref, props.setIsEditMode)

  return (
    <BaseBlockLayout
      ref={ref}
      title={props.title}
      addButton={<InsertButton />}
      actionButtons={
        props.isEditMode
          ? [<ApplyButton key="action-save-btn" onClick={() => props.setIsEditMode(false)} />]
          : []
      }
      menu={[<DuplicateButton key="menu-duplicate-btn" />, <DeleteButton key="menu-delete-btn" />]}
    >
      {props.children}
    </BaseBlockLayout>
  )
}
