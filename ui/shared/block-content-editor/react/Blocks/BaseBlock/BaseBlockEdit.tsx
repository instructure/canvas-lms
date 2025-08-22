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
import {BaseBlockEditWrapper} from './components/BaseBlockEditWrapper'
import {useNode} from '@craftjs/core'
import {useIsEditingBlock} from '../../hooks/useIsEditingBlock'
import {useBlockContentEditorContext} from '../../BlockContentEditorContext'

export const BaseBlockEdit = (
  props: PropsWithChildren<{
    title: string
    backgroundColor: string
  }>,
) => {
  const {id} = useNode()
  const isEditingBlock = useIsEditingBlock()
  const {editingBlock} = useBlockContentEditorContext()

  return (
    <BaseBlockEditWrapper
      title={props.title}
      isEditMode={isEditingBlock}
      setIsEditMode={isEdit => {
        editingBlock.setId(isEdit ? id : null)
      }}
      backgroundColor={props.backgroundColor}
    >
      {props.children}
    </BaseBlockEditWrapper>
  )
}
